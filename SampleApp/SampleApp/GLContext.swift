//
//  GLContext.swift
//  SampleApp
//
//  Created by Rohan on 09/11/20.
//

import GLKit

class GLContext {
  static let shared = EAGLContext(api: .openGLES2)!
  private init() {}
}
