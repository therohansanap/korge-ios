//
//  KorgeViewController.swift
//  SampleApp
//
//  Created by Rohan on 03/11/20.
//

import UIKit
import GLKit
import GameMain
import CoreMedia

class KorgeViewController: GLKViewController {
  
  @IBOutlet weak var timelineCurrentTime: UILabel!
  var context: EAGLContext? = GLContext.shared
  
  var gameWindow2: MyIosGameWindow2?
  var rootGameMain: RootGameMain?
  var touches = [UITouch]()
  
  var isInitialized = false
  var reshape = false
  
  var isPlaying: Bool = false
  var beginPlayingTime: CFTimeInterval = 0
  var seekOffset = 0.0
  var timeline = Timeline()
  let videoManager = VideoManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.isInitialized = false
    self.reshape = true
    
    self.gameWindow2 = MyIosGameWindow2()
    self.rootGameMain = RootGameMain()
    
    setupGL()
  }
  
  private func setupGL() {
    context = GLContext.shared
    EAGLContext.setCurrent(context)

    if let view = self.view as? GLKView, let context = context {
      view.context = context
      delegate = self
    }
  }
  
  override func glkView(_ view: GLKView, drawIn rect: CGRect) {
    let currentTime = CACurrentMediaTime()
    print("CurrentTime - \(currentTime)")
    if isPlaying {
      var diff = currentTime - beginPlayingTime + seekOffset
      diff = diff < 0 ? 0 : (diff > timeline.duration ? timeline.duration : diff)
      timeline.currentTime = diff
    }
    
    printTimelineCurrentTime()
    
    if let nativeImage = videoManager.getFrame(sceneTime: KotlinDouble(value: timeline.currentTime), hostTime: currentTime),
       let videoView1 = MainKt.videoView1 {
      MainKt.update(nativeImage: nativeImage, onView: videoView1)
    }
    self.korgeRenderCall()
  }
  
  func korgeRenderCall() {
    MainKt.sceneTime = timeline.currentTime
//    print("Timeline current time -> \(timeline.currentTime)s")

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
  
  
  func play() {
    print("===========")
    isPlaying = true
    videoManager.player1.play()
    beginPlayingTime = CACurrentMediaTime()
  }
  
  func pause() {
    isPlaying = false
    videoManager.player1.pause()
    seekOffset = timeline.currentTime
  }
  
  func seek(unitPercentage: Float32) {
    pause()
    let offset = timeline.duration * Double(unitPercentage)
    seekOffset = offset
    timeline.currentTime = offset
    
    let seekTime = CMTime(seconds: offset, preferredTimescale: 600)
    
    videoManager.player1.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
  }
  
  private func printTimelineCurrentTime() {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    timelineCurrentTime.text = "\(formatter.string(from: NSNumber(value: timeline.currentTime)) ?? "")"
  }
}

extension KorgeViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
  }
}


class Timeline {
  var duration: Double = 5
  var currentTime: Double = 0
}
