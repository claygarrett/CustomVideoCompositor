//
//  VideoExporter.swift
//  AVPlayerLayerBug
//
//  Created by Clay Garrett on 10/28/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class VideoExporter: NSObject {

    var parentLayer: CALayer?
    var imageLayer: CALayer?
    let videoUrl: URL = URL(fileURLWithPath: Bundle.main.path(forResource: "sorry", ofType: "mov")!)
    let image = UIImage(named: "panda.png")!.cgImage
    
    func export() {    
        // remove existing export file if it exists
        let baseDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let exportUrl = (baseDirectory.appendingPathComponent("export.mov", isDirectory: false) as NSURL).filePathURL!
        deleteExistingFile(url: exportUrl)
        
        // init variables
        let videoAsset: AVAsset = AVAsset(url: videoUrl) as AVAsset
        let tracks = videoAsset.tracks(withMediaType: AVMediaTypeVideo)
        let videoAssetTrack = tracks.first!
        let exportSize: CGFloat = 320
        
        // build video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = CustomVideoCompositor.self
        videoComposition.renderSize = CGSize(width: exportSize, height: exportSize)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        // build instructions
        let instructionTimeRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)
        // we're overlaying this on our source video. here, our source video is 1080 x 1080
        // so even though our final export is 320 x 320, if we want full coverage of the video with our watermark,
        // then we need to make our watermark frame 1080 x 1080
        let watermarkFrame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        let instruction = WatermarkCompositionInstruction(timeRange: instructionTimeRange, watermarkImage: image!, watermarkFrame: watermarkFrame)
        
        videoComposition.instructions = [instruction]
        
        // create exporter and export
        let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exporter!.videoComposition = videoComposition
        exporter!.outputURL = exportUrl
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.exportAsynchronously(completionHandler: { () -> Void in
            switch exporter!.status {
            case .completed:
                print("Done!")
                break
            case .failed:
                print("Failed! \(exporter!.error)")
            default:
                break
            }
        })
    }
    
    func deleteExistingFile(url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        }
        catch _ as NSError {
            
        }
    }
}
