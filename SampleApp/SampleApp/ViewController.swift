//
//  ViewController.swift
//  SampleApp
//
//  Created by Rohan on 03/11/20.
//

import UIKit
import AVFoundation
import GLKit
import GameMain

class ViewController: UIViewController {

  @IBOutlet weak var containerView: UIView!
  
  lazy var korgeVC: KorgeViewController = {
    let vc = storyboard!.instantiateViewController(identifier: "korgeVC") as! KorgeViewController
    return vc
  }()
  
  let asset = AVAsset(url: Bundle.main.url(forResource: "football", withExtension: "mp4")!)
  
  lazy var assetReader: AVAssetReader = try! AVAssetReader(asset: asset)
  
  let outputSettings: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
//    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
    kCVPixelBufferOpenGLESCompatibilityKey as String: true,
  ]
  
  lazy var trackOutput: AVAssetReaderTrackOutput = {
    let track = asset.tracks(withMediaType: .video).first!
    let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
    return trackOutput
  }()
  
  var timer: Timer?
  
  let context = CVEAGLContext(api: .openGLES2)!
  var textureCache: CVOpenGLESTextureCache?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    containerView.addSubview(korgeVC.view)
    
    korgeVC.view.translatesAutoresizingMaskIntoConstraints = false
    korgeVC.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    korgeVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    korgeVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    korgeVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    
    addChild(korgeVC)
    korgeVC.didMove(toParent: self)
    
    assetReader.add(trackOutput)
    assetReader.startReading()
    
    let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
    if err != noErr {
      print("Error - \(err)")
    }
  }
  
  @objc func timerInvocation(_ sender: Timer) {
    autoreleasepool {
      guard let sampleBuffer = trackOutput.copyNextSampleBuffer() else {
        print("Could not get sample buffer")
        return
      }
      
      guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        print("Could not get image buffer")
        return
      }
      
      let pixelBuffer = imageBuffer as CVPixelBuffer
      
      guard let texture = getRGBATexture(for: pixelBuffer) else {
//      guard let lumaTexture = getLumaTexture(for: pixelBuffer),
//            let chromaTexture = getChromaTexture(for: pixelBuffer) else {
        print("returned from here")
        return
      }
      
      MainKt.updateTexture(name: CVOpenGLESTextureGetName(texture))
    }
  }
  
  @IBAction func buttonTapped(_ sender: UIButton) {
    if let timer = timer, timer.isValid {
      timer.invalidate()
    }else {
      self.timer = Timer.scheduledTimer(timeInterval: 0.0416666,
                                        target: self,
                                        selector: #selector(timerInvocation),
                                        userInfo: nil,
                                        repeats: true)
    }
  }
  
  func getRGBATexture(for pixelBuffer: CVPixelBuffer) -> CVOpenGLESTexture? {
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
                                                           GLenum(GL_RGBA),
                                                           GLenum(GL_UNSIGNED_BYTE),
                                                           0,
                                                           &texture)
    
    if texture == nil || err != noErr {
      print("Error at creating RGBA texture - \(err.description)")
    }
    
    return texture
  }
  
  


}









extension ViewController {
  func getLumaTexture(for pixelBuffer: CVPixelBuffer) -> CVOpenGLESTexture? {
    var texture: CVOpenGLESTexture?
    
    guard let textureCache = textureCache else { return nil }
    
    CVOpenGLESTextureCacheFlush(textureCache, 0)
    
    let err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           textureCache,
                                                           pixelBuffer,
                                                           nil,
                                                           GLenum(GL_TEXTURE_2D),
                                                           GLint(GL_RED_EXT),
                                                           Int32(CVPixelBufferGetWidth(pixelBuffer)),
                                                           Int32(CVPixelBufferGetHeight(pixelBuffer)),
                                                           GLenum(GL_RED_EXT),
                                                           GLenum(GL_UNSIGNED_BYTE),
                                                           0,
                                                           &texture)
    
    if texture == nil || err != noErr {
      print("Error at creating luminance texture - \(err.description)")
    }
    
    return texture
  }
  
  func getChromaTexture(for pixelBuffer: CVPixelBuffer) -> CVOpenGLESTexture? {
    var texture: CVOpenGLESTexture?
    
    guard let textureCache = textureCache else { return nil }
    
    CVOpenGLESTextureCacheFlush(textureCache, 0)
    
    let err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           textureCache,
                                                           pixelBuffer,
                                                           nil,
                                                           GLenum(GL_TEXTURE_2D),
                                                           GLint(GL_RG_EXT),
                                                           Int32(CVPixelBufferGetWidth(pixelBuffer)),
                                                           Int32(CVPixelBufferGetHeight(pixelBuffer)),
                                                           GLenum(GL_RG_EXT),
                                                           GLenum(GL_UNSIGNED_BYTE),
                                                           1,
                                                           &texture)
    
    if texture == nil || err != noErr {
      print("Error at creating luminance texture - \(err.description)")
    }
    
    return texture
  }
}

