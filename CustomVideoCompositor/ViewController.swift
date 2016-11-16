//
//  ViewController.swift
//  AVPlayerLayerBug
//
//  Created by Clay Garrett on 11/16/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    override func viewDidLoad() {
        exportVideo()
    }
    
    func exportVideo() {
        let exporter = VideoExporter()
        exporter.export()
    }
}

