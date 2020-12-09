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
  var seekOffset = 0.0
  var timeline = Timeline()
  
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
    print(#function, CACurrentMediaTime())
    if isPlaying {
      let currentTime = CACurrentMediaTime()
      var diff = currentTime - beginPlayingTime + seekOffset
      diff = diff < 0 ? 0 : (diff > timeline.duration ? timeline.duration : diff)
      timeline.currentTime = diff
    }
    
    
    self.korgeRenderCall()
  }
  
  func korgeRenderCall() {
    MainKt.sceneTime = timeline.currentTime

    print("Timeline current time -> \(timeline.currentTime)s")
    
    
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
    isPlaying = false
    seekOffset = timeline.currentTime
//    isPaused = true
  }
  
  func seek(unitPercentage: Float32) {
    pause()
    let offset = timeline.duration * Double(unitPercentage)
    seekOffset = offset
    timeline.currentTime = offset
//    korgeRenderCall()
  }
}

extension KorgeViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
  }
}


class Timeline {
  var duration: Double = 15
  var currentTime: Double = 0
}
