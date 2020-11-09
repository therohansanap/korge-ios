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
  var touches = [UITouch]()
  
  var isInitialized = false
  var reshape = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.isInitialized = false
    self.reshape = true
    
    self.gameWindow2 = MyIosGameWindow2()
    self.rootGameMain = RootGameMain()
    
    setupGL()
    
//    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//      let imgURL = Bundle.main.url(forResource: "mercedes", withExtension: "jpg")!
//      let image = UIImage(contentsOfFile: imgURL.path)!
//      let textureID = GLHelper.createTexture(from: image)
//      
//      
//      MainKt.updateTexture(name: UInt32(textureID), width: 512, height: 512)
//    }
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
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.touches.removeAll()
    self.gameWindow2?.gameWindow.dispatchTouchEventStartStart()
    self.addTouches(touches: touches)
    self.gameWindow2?.gameWindow.dispatchTouchEventEnd()
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.gameWindow2?.gameWindow.dispatchTouchEventStartMove()
    self.addTouches(touches: touches)
    self.gameWindow2?.gameWindow.dispatchTouchEventEnd()
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.gameWindow2?.gameWindow.dispatchTouchEventStartEnd()
    self.addTouches(touches: touches)
    self.gameWindow2?.gameWindow.dispatchTouchEventEnd()
  }
  
  func addTouches(touches: Set<UITouch>) {
    for touch in touches {
      let point = touch.location(in: self.view)
      var index = -1
      
      for n in 0..<self.touches.count {
        if self.touches[n] == touch {
          index = n
          break
        }
      }
      
      if index == -1 {
        index = self.touches.count
        self.touches.append(touch)
      }
      
      self.gameWindow2?.gameWindow.dispatchTouchEventAddTouch(id: Int32(index),
                                                              x: Double(point.x * self.view.contentScaleFactor),
                                                              y: Double(point.y * self.view.contentScaleFactor))
    }
  }
}

extension KorgeViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
    
  }
}
