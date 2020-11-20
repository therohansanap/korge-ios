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

class ViewController2: UIViewController {
  
  let context = GLContext.shared
  
  var frameBuffer = GLuint()
  var colorRenderBuffer = GLuint()
  
  let videoRecorder = VideoRecorder(size: CGSize(width: 512, height: 512))
  
  var reshape = true
  var isInitialized = false
  var gameWindow2: MyIosGameWindow2?
  var rootGameMain: RootGameMain?
  
  var timer: Timer?
  var time: TimeInterval = 0.0
  
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
  }
  
  @IBAction func startTapped(_ sender: UIButton) {
    videoRecorder?.startRecording()
    timer?.invalidate()
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
  }
}
