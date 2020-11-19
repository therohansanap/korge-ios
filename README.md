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







