//
//  ViewController.swift
//  SampleApp
//
//  Created by Rohan on 03/11/20.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

  @IBOutlet weak var containerView: UIView!
  
  lazy var korgeVC: KorgeViewController = {
    let vc = storyboard!.instantiateViewController(identifier: "korgeVC") as! KorgeViewController
    return vc
  }()
  
  let asset = AVAsset(url: Bundle.main.url(forResource: "football", withExtension: "mp4")!)
  
  lazy var assetReader: AVAssetReader = try! AVAssetReader(asset: asset)
  
  let outputSettings: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferMetalCompatibilityKey as String: true
  ]
  
  lazy var trackOutput: AVAssetReaderTrackOutput = {
    let track = asset.tracks(withMediaType: .video).first!
    let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
    return trackOutput
  }()
  
  var timer: Timer?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    containerView.addSubview(korgeVC.view)
    
    korgeVC.view.translatesAutoresizingMaskIntoConstraints = false
    korgeVC.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    korgeVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    korgeVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    korgeVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    
    addChild(korgeVC)
    korgeVC.didMove(toParent: self)
    
    assetReader.add(trackOutput)
    assetReader.startReading()
  }
  
  var counter = 0
  @objc func timerInvocation(_ sender: Timer) {
    guard let sampleBuffer = trackOutput.copyNextSampleBuffer() else { return }
  }
  
  @IBAction func buttonTapped(_ sender: UIButton) {
    if let timer = timer, timer.isValid {
      timer.invalidate()
    }else {
      self.timer = Timer.scheduledTimer(timeInterval: 0.0416666,
                                        target: self,
                                        selector: #selector(timerInvocation),
                                        userInfo: nil,
                                        repeats: true)
    }
  }


}

