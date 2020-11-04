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
  
  var context: EAGLContext?
  
  var gameWindow2: MyIosGameWindow2?
  var rootGameMain: RootGameMain?
  
  var isInitialized = false
  var reshape = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.isInitialized = false
    self.reshape = true
    
    self.gameWindow2 = MyIosGameWindow2()
    self.rootGameMain = RootGameMain()
    
    setupGL()
  }
  
  private func setupGL() {
    context = EAGLContext(api: .openGLES3)
    EAGLContext.setCurrent(context)

    if let view = self.view as? GLKView, let context = context {
      view.context = context
      delegate = self
    }
  }
  
  override func glkView(_ view: GLKView, drawIn rect: CGRect) {
//    glClearColor(0.85, 0.85, 0.85, 1.0)
//    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    
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
}

extension KorgeViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
    
  }
}
