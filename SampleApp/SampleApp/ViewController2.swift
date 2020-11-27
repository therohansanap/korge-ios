//
//  ViewController2.swift
//  SampleApp
//
//  Created by Rohan on 17/11/20.
//

import UIKit
import OpenGLES
import CoreVideo
import GameMain
import AVFoundation

class ViewController2: UIViewController {
  
  let context = GLContext.shared
  var textureCache: CVOpenGLESTextureCache?
  
  var frameBuffer = GLuint()
  var colorRenderBuffer = GLuint()
  
  let videoRecorder = VideoRecorder(size: CGSize(width: 512, height: 512))
  
  var reshape = true
  var isInitialized = false
  var gameWindow2: MyIosGameWindow2?
  var rootGameMain: RootGameMain?
  
  var timer: Timer?
  var time: TimeInterval = 0.0
  
  let asset = AVAsset(url: Bundle.main.url(forResource: "football", withExtension: "mp4")!)
  lazy var assetReader: AVAssetReader = try! AVAssetReader(asset: asset)
  let outputSettings: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferOpenGLESCompatibilityKey as String: true
  ]
  lazy var trackOutput: AVAssetReaderTrackOutput = {
    let track = asset.tracks(withMediaType: .video).first!
    let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
    return trackOutput
  }()
  
  var nativeImages = [GLuint: RSNativeImage]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.isInitialized = false
    self.reshape = true
    
    self.gameWindow2 = MyIosGameWindow2()
    self.rootGameMain = RootGameMain()
    
    EAGLContext.setCurrent(context)
    
    glGenFramebuffers(1, &frameBuffer)
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)

    glGenRenderbuffers(1, &colorRenderBuffer);
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer);
    glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_RGBA8), 1024, 1024);
    glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderBuffer);

    let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))

    if status != GLenum(GL_FRAMEBUFFER_COMPLETE) {
      fatalError("failed to make complete frame buffer object \(status)")
    }
    
    assetReader.add(trackOutput)
    assetReader.startReading()
    
    let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
    if err != noErr {
      print("Error - \(err)")
    }
  }
  
  @IBAction func startTapped(_ sender: UIButton) {
    videoRecorder?.startRecording()
    timer?.invalidate()
    MainKt.mayank = getFrame
    timer = Timer.scheduledTimer(timeInterval: 0.033333333,
                                 target: self,
                                 selector: #selector(timerInvocation),
                                 userInfo: nil,
                                 repeats: true)
    
    print("Started accepting frames")
  }
  
  @IBAction func doneTapped(_ sender: UIButton) {
    videoRecorder?.endRecording {
      print("Check video file")
    }
  }
  
  @objc
  func renderFrame() {
    if !self.isInitialized {
      self.isInitialized = true
      self.gameWindow2?.gameWindow.dispatchInitEvent()
      self.rootGameMain?.runMain()
      self.reshape = true;
    }
    
    let width = self.view.bounds.size.width * self.view.contentScaleFactor
    let height = self.view.bounds.size.height * self.view.contentScaleFactor
    if self.reshape {
      self.reshape = false
      self.gameWindow2?.gameWindow.dispatchReshapeEvent(x: 0, y: 0, width: Int32(width), height: Int32(height))
    }
    
    self.gameWindow2?.gameWindow.frame()
  }
  
  @objc
  func timerInvocation() {
    guard time < 5 else {
      timer?.invalidate()
      videoRecorder?.endRecording {
        print("Check video file")
      }
      return
    }
    print(time)
    renderFrame()
    videoRecorder?.writeFrame(time: time)
    time += 0.033333333
//    time += 0.04166666667
  }
  
  func getFrame() -> RSNativeImage? {
    print(#function)
    guard let sampleBuffer = trackOutput.copyNextSampleBuffer() else {
      print("Could not get sample buffer")
      return nil
    }
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      print("Could not get image buffer")
      return nil
    }
    
    let pixelBuffer = imageBuffer as CVPixelBuffer
    
    guard let texture = getRGBATexture(for: pixelBuffer) else {
      print("returned from here")
      return nil
    }
    
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
                                                           GLenum(GL_BGRA),
                                                           GLenum(GL_UNSIGNED_BYTE),
                                                           0,
                                                           &texture)
    
    if texture == nil || err != noErr {
      print("Error at creating RGBA texture - \(err.description)")
    }
    
    return texture
  }
}
