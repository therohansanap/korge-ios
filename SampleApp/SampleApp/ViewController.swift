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
  }


}

