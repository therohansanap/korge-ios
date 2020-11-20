# Introduction
This project is made to experiment around how can we do hardware decoding of a video file on platform side (iOS) and then use those decoded frames to pass to Korge and render them as if we are playing a video.

# AssetReader
We use `AVAssetReader` along with `AVAssetReaderTrackOutput` to get decoded video frames from a video file. You will find the setup for this inside **ViewController.swift** file.

# Experiments

You find implementation of all these trials inside **ViewController.swift** in `func buttonTapped(_:)`

To work with premade textures, we have defined `RSNativeImage` class. This class helps to use already created texture which is created on platform side and then passed to Korge sample.

## Trial - 1
Open **VideoOnKorge** project and you will find following method in **main.kt** file:
```
fun updateTexture(name: UInt, width: Int, height: Int, target: Int?) {
	println(" " + name + " =============================")
	var texture = RSNativeImage(width, height, name, target)
	imageRohan?.bitmap = texture.slice()
}
```
The above function creates a hook using which we can pass premade texture with it's name and other parameters so that it can be consumed/processed on Korge side.

Inside **ViewController.swift** file, you will see following code under Trial-1 section:
```
if let timer = timer, timer.isValid {
    timer.invalidate()
}else {
    self.timer = Timer.scheduledTimer(timeInterval: 0.0416666,
                                      target: self,
                                      selector: #selector(timerInvocation),
                                      userInfo: nil,
                                      repeats: true)
}
```
A repeated timer function `timerInvocation` is executed for every 41ms which does following:

    1. Reads next sample buffer from `trackOutput`.
    2. Converts extracts `CVPixelBuffer` from `CMSampleBuffer`.
    3. Converts `pixelBuffer` to `CVOpenGLESTexture` object.
    4. Extracts information like name/id and other attributes this texture and pass them to Korge using previously defined function hook.

### Expectations
It was expected to get a video output just like we play it using any video player.

### Output
This is how the video looked like - https://youtu.be/e34usPzEgWg. You can also run the project on your machine to view realtime output .

### Problem
Video in the output is stuttering a lot. No smooth playbackl as with video player.

### What we achieved
We were able to transfer a pre-made texture from platform side to Korge side and utilize it to apply on scene/plane.

## Trial - 3
We saw the flickering in trial-1. So I thought of putting frame one by one on a button tap instead of running a predefined timer. In this trial, I use the same function `func timerInvocation()` that is used by the timer invocation but it is fired individually on button tap. This extracts one frame from `trackOutput` and passes it to korge on every button tap.

### Expectations
I was expecting for frame change to looks instataneous as we are passing premade texture to Korge.

### Output
This is how the output looked - https://youtu.be/mdfkrys1npk. You can also run the project on your machine to view realtime output.

### Observation and problem
On every tap, we are sending new frame's texture to Korge for applying. We can clearly see a lag in applying the texture. We were expeting this to happen instantaneously. This lag in applying texture is probably also causing video flickering / stuttering that we saw in trial-1.

## Trial - 4
So, in this trial I changed our approach a little. Here, the decoding of frame and conversion to texture happens *on-demand*. Meaning, a callback variable was added on Korge side `var mayank: (() -> RSNativeImage?)? = null` which expects an `RSNativeImage` to be returned when invoked. Then, we added callback invokation logic inside `override fun renderInternal(ctx: RenderContext)` of `RSImage` class because this method is called on every draw cycle. Basically, what we are doing here is on every draw cycle when `fun renderInternal(ctx: RenderContext)` will be called, this call will invoke the callback demanding us to decode a frame and convert it to texture and `RSNativeImage` and then return that object via callback. This returned object is then used and apply to bitmap of `RSImage`.

```
override fun renderInternal(ctx: RenderContext) {
    mayank?.invoke()?.let {
		this.bitmap = it.slice()
	}

	super.renderInternal(ctx)
}
```

On the platform side, a function `func getFrame() -> RSNativeImage?` is described to implement this callback and suffise the demand of decoding and passing the texture on demand.

### Observation
This show almost a black screen with no frame output. Our screen refresh rate is 60hz hence I think demanding, decoding and applying new frame every 16ms was getting too costly for the rendering system.

### Modification
We modified the demand logic to invoke the callback every ~30ms to see if anything changes on output side.

```
override fun renderInternal(ctx: RenderContext) {
	if (foo % 2 == 0) {
		mayank?.invoke()?.let {
			println("" + width + " " + height)
			println(it.forcedTexId)
			println("====================")
			this.bitmap = it.slice()
		}
	}
	foo += 1

	super.renderInternal(ctx)
}
```

### Observation
We see this is giving same flickering video output like trial-1 https://youtu.be/BYK6-i_yTcE.

## Trial - 5
In this trial we connect to on-demand callback on one tap and disconnect it on another tap.

### Observation
The refresh cycle keeps on going. When we disconnect the callback, we can see the still frame after one refresh cycle has completed. This tells us that Korge is taking about 1 refresh cycle to complete the application of texture and display it. Hence that black/blank appears for split second while we see it.


