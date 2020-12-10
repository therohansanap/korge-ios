import com.soywiz.korge.*
import com.soywiz.korge.animate.animate
import com.soywiz.korge.render.RenderContext
import com.soywiz.korge.scene.Module
import com.soywiz.korge.scene.Scene
import com.soywiz.korge.view.*
import com.soywiz.korim.bitmap.Bitmap
import com.soywiz.korim.bitmap.NativeImage
import com.soywiz.korim.bitmap.slice
import com.soywiz.korim.color.RgbaArray
import com.soywiz.korim.format.*
import com.soywiz.korinject.AsyncInjector
import com.soywiz.korio.file.std.*

suspend fun main() = Korge(Korge.Config(module = MyModule))

object MyModule : Module() {
	override val mainScene = MyScene1::class

	override suspend fun AsyncInjector.configure() {
		mapInstance(MyDependency("HELLO WORLD"))
		mapPrototype { MyScene1(get()) }
	}
}

class MyDependency(val value: String)

class MyScene1(val myDependency: MyDependency) : Scene() {

	override suspend fun Container.sceneInit() {
		videoView1 = rsImage(resourcesVfs["korge.png"].readBitmap()).anchor(0.5, 0.5).xy(200.0, 200.0)
//		videoView2 = rsImage(resourcesVfs["korge.png"].readBitmap()).anchor(0.5, 0.5).xy(300.0, 300.0)
//		videoView3 = rsImage(resourcesVfs["korge.png"].readBitmap()).anchor(0.5, 0.5).xy(400.0, 400.0)

		addUpdater {
			videoView1?.visible = sceneTime <= 5
//			videoView2?.visible = (sceneTime > 5) && (sceneTime <= 10)
//			videoView3?.visible = (sceneTime > 10) && (sceneTime <= 15)

			/*val degreeCalculation = (360.0 / 5.0) * (sceneTime % 5)
			if (sceneTime <= 5) {
				videoView1?.rotationDegrees = degreeCalculation
			}else if ((sceneTime > 5) && (sceneTime <= 10)) {
				videoView2?.rotationDegrees = degreeCalculation
			}else if ((sceneTime > 10) && (sceneTime <= 15)) {
				videoView3?.rotationDegrees = degreeCalculation
			}*/
		}
	}
}

const val GL_TEXTURE_EXTERNAL_OES = 0x8D65
const val GL_TEXTURE_2D = 0x0DE1

class RSNativeImage(width: Int, height: Int, val name2: UInt, val target2: Int?) : NativeImage(width, height, null, true) {
	override val forcedTexId: Int get() = name2.toInt()
	override val forcedTexTarget: Int get() = if (target2 != null) target2 else GL_TEXTURE_2D

	override fun readPixelsUnsafe(x: Int, y: Int, width: Int, height: Int, out: RgbaArray, offset: Int) {
		TODO("Not yet implemented")
	}

	override fun writePixelsUnsafe(x: Int, y: Int, width: Int, height: Int, out: RgbaArray, offset: Int) {
		TODO("Not yet implemented")
	}
}

class RSImage(bitmap: Bitmap) : Image(bitmap) {
	var callbackForVideoFrame: ((sceneTime: Double) -> RSNativeImage?)? = null

	override fun renderInternal(ctx: RenderContext) {
		/*when {
			videoView1 === this -> {
				println("Rendering Video View 1")
			}
			videoView2 === this -> {
				println("Rendering Video View 2")
			}
			videoView3 === this -> {
				println("Rendering Video View 3")
			}
		}*/

		val returnedImage = callbackForVideoFrame?.let { it(sceneTime) }
		if (returnedImage != null) {
			this.bitmap = returnedImage.slice()
		}

		super.renderInternal(ctx)
	}
}

inline fun Container.rsImage(
		texture: Bitmap, callback: @ViewDslMarker Image.() -> Unit = {}
): RSImage = RSImage(texture).addTo(this, callback)


var videoView1: RSImage? = null
//var videoView2: RSImage? = null
//var videoView3: RSImage? = null

var sceneTime: Double = 0.0

fun update(nativeImage: RSNativeImage, onView: RSImage) {
	onView.bitmap = nativeImage.slice()
}


