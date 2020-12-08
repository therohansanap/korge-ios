//
//  ViewController3.swift
//  SampleApp
//
//  Created by Rohan on 07/12/20.
//

import UIKit
import AVFoundation
import GameMain

class ViewController3: UIViewController {
  
  @IBOutlet weak var containerView: UIView!
  
  lazy var korgeVC: KorgeViewController = {
    return storyboard!.instantiateViewController(identifier: "korgeVC") as! KorgeViewController
  }()
  
  let outputSettings: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferOpenGLESCompatibilityKey as String: true
  ]
  
  let url1 = Bundle.main.url(forResource: "video1-30fps", withExtension: "mp4")!
  let url2 = Bundle.main.url(forResource: "video2-60fps", withExtension: "mp4")!
  let url3 = Bundle.main.url(forResource: "video3-24fps", withExtension: "mp4")!
  
  lazy var asset1 = AVAsset(url: url1)
  lazy var asset2 = AVAsset(url: url2)
  lazy var asset3 = AVAsset(url: url3)
  
  lazy var playerItem1 = AVPlayerItem(asset: asset1)
  lazy var playerItem2 = AVPlayerItem(asset: asset2)
  lazy var playerItem3 = AVPlayerItem(asset: asset3)
  
  lazy var itemVideoOutput1: AVPlayerItemVideoOutput = {
    let output = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
    return output
  }()
  lazy var itemVideoOutput2: AVPlayerItemVideoOutput = {
    let output = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
    return output
  }()
  lazy var itemVideoOutput3: AVPlayerItemVideoOutput = {
    let output = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
    return output
  }()
  
  lazy var player1 = AVPlayer(playerItem: playerItem1)
  lazy var player2 = AVPlayer(playerItem: playerItem2)
  lazy var player3 = AVPlayer(playerItem: playerItem3)
  
  var timer: Timer?
  
  let context = GLContext.shared
  var textureCache: CVOpenGLESTextureCache?
  var nativeImages = [GLuint: RSNativeImage]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupKorgeVC()
    
    playerItem1.add(itemVideoOutput1)
    playerItem2.add(itemVideoOutput2)
    playerItem3.add(itemVideoOutput3)
    
    player1.automaticallyWaitsToMinimizeStalling = false
    player2.automaticallyWaitsToMinimizeStalling = false
    player3.automaticallyWaitsToMinimizeStalling = false
    
    let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
    if err != noErr {
      fatalError("Error - \(err)")
    }
  }
  
  private func setupKorgeVC() {
    containerView.addSubview(korgeVC.view)
    
    korgeVC.view.translatesAutoresizingMaskIntoConstraints = false
    korgeVC.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    korgeVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    korgeVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    korgeVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    
    addChild(korgeVC)
    korgeVC.didMove(toParent: self)
  }
  
  @IBAction func playTapped(_ sender: UIButton) {
    if timer != nil {
      timer?.invalidate()
      korgeVC.isPaused = false
    }else {
      korgeVC.isPaused = true
    }
    
    MainKt.videoView1?.callbackForVideoFrame = getFrame
    MainKt.videoView2?.callbackForVideoFrame = getFrame
    MainKt.videoView3?.callbackForVideoFrame = getFrame
    
    timer = Timer.scheduledTimer(timeInterval: 0.0333,
                                 target: self,
                                 selector: #selector(playTimer(_:)),
                                 userInfo: nil,
                                 repeats: true)
    
    let currentTime = CMClock.hostTimeClock.time
    let currentTimePlus5 = CMTimeAdd(CMClock.hostTimeClock.time, CMTime(seconds: 5, preferredTimescale: 600))
    let currentTimePlus10 = CMTimeAdd(CMClock.hostTimeClock.time, CMTime(seconds: 10, preferredTimescale: 600))
    player1.setRate(1.0, time: .zero, atHostTime: currentTime)
    player2.setRate(1.0, time: .zero, atHostTime: currentTimePlus5)
    player3.setRate(1.0, time: .zero, atHostTime: currentTimePlus10)
    
  }
  
  @IBAction func exportTapped(_ sender: UIButton) {
  }
  
  @objc
  func playTimer(_ sender: Timer) {
    guard MainKt.sceneTime <= 15 else {
      MainKt.sceneTime = 0
      timer?.invalidate()
      korgeVC.isPaused = false
      return
    }
    
    makeCanvasDrawCall()
    MainKt.sceneTime += sender.timeInterval
  }
  
  private func makeCanvasDrawCall() {
    let glView = korgeVC.view as! GLKView
    glView.bindDrawable()
    korgeVC.singleRenderCall()
    korgeVC.context?.presentRenderbuffer(Int(GL_RENDERBUFFER))
  }
  
  func getFrame(sceneTime: KotlinDouble) -> RSNativeImage? {
    let currentTime = CACurrentMediaTime()
    var itemVideoOutput: AVPlayerItemVideoOutput!
    
    switch sceneTime.doubleValue {
    case 0...5        : itemVideoOutput = itemVideoOutput1
    case 5.0001...10  : itemVideoOutput = itemVideoOutput2
    case 10.0001...15 : itemVideoOutput = itemVideoOutput3
    default           : return nil
    }
    
    let itemTime = itemVideoOutput.itemTime(forHostTime: currentTime)
    
    if itemVideoOutput.hasNewPixelBuffer(forItemTime: itemTime),
       let pixelBuffer = itemVideoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil),
       let texture = getRGBATexture(for: pixelBuffer),
       let nativeImage = getRSNativeImage(from: texture, pixelBuffer: pixelBuffer) {
      return nativeImage
    }else {
      return nil
    }
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
  
}