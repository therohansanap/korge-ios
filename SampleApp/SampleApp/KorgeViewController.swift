//
//  KorgeViewController.swift
//  SampleApp
//
//  Created by Rohan on 03/11/20.
//

import UIKit
import GLKit

class KorgeViewController: GLKViewController {
  
  var context: EAGLContext?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    print(view is GLKView)
    
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
    glClearColor(0.85, 0.85, 0.85, 1.0)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
  }
}

extension KorgeViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
    
  }
}
