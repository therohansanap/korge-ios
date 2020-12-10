//
//  ViewController3.swift
//  SampleApp
//
//  Created by Rohan on 07/12/20.
//

import UIKit
import AVFoundation
import GameMain

class ViewController3: UIViewController {
  
  @IBOutlet weak var containerView: UIView!
  
  lazy var korgeVC: KorgeViewController = {
    return storyboard!.instantiateViewController(identifier: "korgeVC") as! KorgeViewController
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupKorgeVC()
  }
  
  private func setupKorgeVC() {
    containerView.addSubview(korgeVC.view)
    
    korgeVC.view.translatesAutoresizingMaskIntoConstraints = false
    korgeVC.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    korgeVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    korgeVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    korgeVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    
    addChild(korgeVC)
    korgeVC.didMove(toParent: self)
  }
  
  @IBAction func playTapped(_ sender: UIButton) {
    let title = sender.title(for: .normal)
    if title == "Play" {
      sender.setTitle("Pause", for: .normal)
      korgeVC.play()
    }else {
      sender.setTitle("Play", for: .normal)
      korgeVC.pause()
    }
  }
  
  @IBAction func seekerSeeked(_ sender: UISlider) {
    print("Did seek")
    korgeVC.seek(unitPercentage: sender.value)
  }
  
  @IBAction func exportTapped(_ sender: UIButton) {
  }
}
