//
//  KorgeViewController+TouchHandling.swift
//  SampleApp
//
//  Created by Rohan on 09/12/20.
//

import UIKit

//MARK - Touch handling methods
extension KorgeViewController {
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
