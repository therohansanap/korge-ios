//
//  VideoManager.swift
//  SampleApp
//
//  Created by Rohan on 10/12/20.
//

import AVFoundation
import OpenGLES
import GameMain

class VideoManager {
  let outputSettings: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferOpenGLESCompatibilityKey as String: true
  ]
  
  let url1 = Bundle.main.url(forResource: "video1-30fps", withExtension: "mp4")!
  let asset1: AVAsset
  let playerItem1: AVPlayerItem
  let itemVideoOutput1: AVPlayerItemVideoOutput
  let player1: AVPlayer
  
  let context = GLContext.shared
  var textureCache: CVOpenGLESTextureCache?
  var nativeImages = [GLuint: RSNativeImage]()
  
  init() {
    asset1 = AVAsset(url: url1)
    playerItem1 = AVPlayerItem(asset: asset1)
    itemVideoOutput1 = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
    playerItem1.add(itemVideoOutput1)
    player1 = AVPlayer(playerItem: playerItem1)
    
    let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
    if err != noErr { fatalError("Error - \(err)") }
  }
  
  private func getRGBATexture(for pixelBuffer: CVPixelBuffer) -> CVOpenGLESTexture? {
    var texture: CVOpenGLESTexture?
    
    guard let textureCache = textureCache else { return nil }
    
    CVOpenGLESTextureCacheFlush(textureCache, 0)
    
    let err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           textureCache,
                                                           pixelBuffer,
                                                           nil,
                                                           GLenum(GL_TEXTURE_2D),
                                                           GLint(GL_RGBA),
                                                           Int32(CVPixelBufferGetWidth(pixelBuffer)),
                                                           Int32(CVPixelBufferGetHeight(pixelBuffer)),
                                                           GLenum(GL_BGRA),
                                                           GLenum(GL_UNSIGNED_BYTE),
                                                           0,
                                                           &texture)
    
    if texture == nil || err != noErr {
      print("Error at creating RGBA texture - \(err.description)")
    }
    
    return texture
  }
  
  private func getRSNativeImage(from texture: CVOpenGLESTexture, pixelBuffer: CVPixelBuffer) -> RSNativeImage? {
    let target = CVOpenGLESTextureGetTarget(texture)
    let id = CVOpenGLESTextureGetName(texture)
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    
    if let nativeImage = nativeImages[id] {
      return nativeImage
    }else {
      let nativeImage = RSNativeImage(width: Int32(width),
                                      height: Int32(height),
                                      name2: id,
                                      target2: KotlinInt(int: Int32(target)))
      nativeImages[id] = nativeImage
      return nativeImage
    }
  }
  
  
  func getFrame(sceneTime: KotlinDouble, hostTime: CFTimeInterval) -> RSNativeImage? {
//    let itemTime = itemVideoOutput1.itemTime(forHostTime: hostTime)
    let itemTime = CMTime(seconds: sceneTime.doubleValue, preferredTimescale: 600)
    
    let string = """
    ==============================
    SceneTime - \(sceneTime.doubleValue)
    ItemTime - \(CMTimeGetSeconds(itemTime))
    """
    print(string)

   
    guard itemVideoOutput1.hasNewPixelBuffer(forItemTime: itemTime) else {
      print("hasNewPixelBuffer = false")
      return nil
    }

    guard let pixelBuffer = itemVideoOutput1.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) else {
      print("copyPixelBuffer failed")
      return nil
    }

    guard let texture = getRGBATexture(for: pixelBuffer) else {
      return nil
    }

    guard let nativeImage = getRSNativeImage(from: texture, pixelBuffer: pixelBuffer) else {
      print("getRSNativeImage failed")
      return nil
    }

    return nativeImage
  }
}
