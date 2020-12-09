//
//  KorgeViewController.swift
//  SampleApp
//
//  Created by Rohan on 03/11/20.
//

import UIKit
import GLKit
import GameMain

class KorgeViewController: GLKViewController {
  
  var context: EAGLContext? = GLContext.shared
  
  var gameWindow2: MyIosGameWindow2?
  var rootGameMain: RootGameMain?
  var touches = [UITouch]()
  
  var isInitialized = false
  var reshape = false
  
  var isPlaying: Bool = false
  var beginPlayingTime: CFTimeInterval = 0
  var timeline = Timeline()
  
  private var _originalPreferredFramesPerSecond: Int = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    _originalPreferredFramesPerSecond = preferredFramesPerSecond
//    preferredFramesPerSecond = 1
//    resumeOnDidBecomeActive = false
    
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
    if isPlaying {
      let currentTime = CACurrentMediaTime()
      var diff = currentTime - beginPlayingTime
      diff = diff < 0 ? 0 : (diff > timeline.duration ? timeline.duration : diff)
      timeline.currentTime = diff
    }
    
    MainKt.sceneTime = timeline.currentTime

    print("Timeline current time -> \(timeline.currentTime)s")
    self.korgeRenderCall()
  }
  
  func korgeRenderCall() {
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
    isPlaying = true
    beginPlayingTime = CACurrentMediaTime()
//    isPaused = false
    
  }
  
  func pause() {
    
  }
  
  func resume() {
    
  }
  
  func seek() {
    
  }
}

extension KorgeViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
    guard preferredFramesPerSecond != 1 else {
      isPaused = true
      preferredFramesPerSecond = _originalPreferredFramesPerSecond
      return
    }
  }
}


class Timeline {
  var duration: Double = 15
  var currentTime: Double = 0
}
