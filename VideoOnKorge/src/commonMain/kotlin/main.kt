import com.soywiz.klock.seconds
import com.soywiz.korge.*
import com.soywiz.korge.input.onClick
import com.soywiz.korge.input.onOut
import com.soywiz.korge.input.onOver
import com.soywiz.korge.render.RenderContext
import com.soywiz.korge.scene.Module
import com.soywiz.korge.scene.Scene
import com.soywiz.korge.tween.*
import com.soywiz.korge.view.*
import com.soywiz.korim.bitmap.Bitmap
import com.soywiz.korim.bitmap.Bitmaps
import com.soywiz.korim.bitmap.NativeImage
import com.soywiz.korim.bitmap.slice
import com.soywiz.korim.color.Colors
import com.soywiz.korim.color.RgbaArray
import com.soywiz.korim.format.*
import com.soywiz.korinject.AsyncInjector
import com.soywiz.korio.file.std.*
import com.soywiz.korma.geom.degrees
import com.soywiz.korma.interpolation.Easing

//suspend fun main() = Korge(width = 512, height = 512, bgcolor = Colors["#2b2b2b"]) {
//	val minDegrees = (-16).degrees
//	val maxDegrees = (+16).degrees
//
//	val image = image(resourcesVfs["korge.png"].readBitmap()) {
//		rotation = maxDegrees
//		anchor(.5, .5)
//		scale(.8)
//		position(256, 256)
//	}
//
//	while (true) {
//		image.tween(image::rotation[minDegrees], time = 1.seconds, easing = Easing.EASE_IN_OUT)
//		image.tween(image::rotation[maxDegrees], time = 1.seconds, easing = Easing.EASE_IN_OUT)
//	}
//
////	val circle = circle(radius = 50.0, color = Colors.GREEN).xy(-50, -50)
//}

suspend fun main() = Korge(Korge.Config(module = MyModule))

var imageRohan: Image? = null

object MyModule : Module() {
	override val mainScene = MyScene1::class

	override suspend fun AsyncInjector.configure() {
		mapInstance(MyDependency("HELLO WORLD"))
		mapPrototype { MyScene1(get()) }
	}
}

class MyDependency(val value: String)

class MyScene1(val myDependency: MyDependency) : Scene() {
	var imageNode: Image? = null

	override suspend fun Container.sceneInit() {
		text("MyScene1: ${myDependency.value}") { filtering = false }
		imageNode = rsImage(resourcesVfs["korge.png"].readBitmap()) {
			onClick {
				if (imageRohan == null) {
					imageRohan = imageNode
				}else {
					println("imageRohan already set")
				}
			}
		}
	}
}

fun updateTexture(name: UInt, width: Int, height: Int, target: Int?) {
	println(" " + name + " =============================")
	var texture = RSNativeImage(width, height, name, target)
	imageRohan?.bitmap = texture.slice()
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

class RSImage(bitmap: Bitmap): Image(bitmap) {
	var foo = 0
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
}

inline fun Container.rsImage(
		texture: Bitmap, anchorX: Double = 0.0, anchorY: Double = 0.0, callback: @ViewDslMarker Image.() -> Unit = {}
): Image = RSImage(texture).addTo(this, callback)

var mayank: (() -> RSNativeImage)? = null


