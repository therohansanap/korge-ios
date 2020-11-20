import Metal
import AVFoundation
import OpenGLES
import CoreImage

class VideoRecorder {
  var isRecording = false

  private var assetWriter: AVAssetWriter
  private var assetWriterVideoInput: AVAssetWriterInput
  private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor
  
  private var textureCache: CVOpenGLESTextureCache?
  
  private var screenShotPixelBufferPool: CVPixelBufferPool?

  init?(size: CGSize) {
    let timeIntervalSince1970 = Date().timeIntervalSince1970
    let timeString = "\(timeIntervalSince1970)".split(separator: ".").first!
    guard let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("\(timeString).mp4") else {
      return nil
    }

    do {
      assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
    } catch {
      return nil
    }

    let outputSettings: [String: Any] = [
      AVVideoCodecKey : AVVideoCodecType.h264,
      AVVideoWidthKey : size.width,
      AVVideoHeightKey : size.height,
      AVVideoColorPropertiesKey: [
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
      ]
    ]

    assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
    assetWriterVideoInput.expectsMediaDataInRealTime = false

    let sourcePixelBufferAttributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String : size.width,
      kCVPixelBufferHeightKey as String : size.height
    ]

    assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: assetWriterVideoInput,
      sourcePixelBufferAttributes: sourcePixelBufferAttributes
    )

    assetWriter.add(assetWriterVideoInput)
    
    let status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, GLContext.shared, nil, &self.textureCache)
    guard status == kCVReturnSuccess else { return nil }
    
    let status2 = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, sourcePixelBufferAttributes as CFDictionary, &screenShotPixelBufferPool)
    guard status2 == kCVReturnSuccess else { return nil }
  }

  func startRecording() {
    let result = assetWriter.startWriting()
    assert(result)
    assetWriter.startSession(atSourceTime: CMTime.zero)
    isRecording = true
  }

  func endRecording(_ completionHandler: @escaping () -> ()) {
    isRecording = false
    assetWriterVideoInput.markAsFinished()
    assetWriter.finishWriting(completionHandler: completionHandler)
  }

  func writeFrame(forTexture texture: MTLTexture, time: TimeInterval) {
    if !isRecording {
      return
    }

    while !assetWriterVideoInput.isReadyForMoreMediaData {}

    guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
      print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
      return
    }

    var maybePixelBuffer: CVPixelBuffer? = nil
    let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
    if status != kCVReturnSuccess {
      print("Could not get pixel buffer from asset writer input; dropping frame...")
      return
    }

    guard let pixelBuffer = maybePixelBuffer else { return }
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, .shouldPropagate)
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_709_2, .shouldPropagate)

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!

    // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)

    texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

    let presentationTime = getCMTime(from: time)
    assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
  }
  
  func writeFrame(time: TimeInterval) {
    if !isRecording {
      return
    }

    while !assetWriterVideoInput.isReadyForMoreMediaData {}
    
    guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
      print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
      return
    }
    
    var maybePixelBuffer: CVPixelBuffer? = nil
    let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
    if status != kCVReturnSuccess {
      print("Could not get pixel buffer from asset writer input; dropping frame...")
      return
    }

    guard let pixelBuffer = maybePixelBuffer else { return }
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, .shouldPropagate)
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_709_2, .shouldPropagate)
    
    let bufferSize = CGSize(width: 512, height: 512)
    
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    
    glReadPixels(0, 0, GLsizei(bufferSize.width), GLsizei(bufferSize.height), GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(pixelBuffer))
    
    let presentationTime = self.getCMTime(from: time)
    assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
  }
  
  func getCMTime(from timeInterval: TimeInterval) -> CMTime {
    let presentationTime = CMTimeMakeWithSeconds(timeInterval, preferredTimescale: 240)
    return presentationTime
  }
}
