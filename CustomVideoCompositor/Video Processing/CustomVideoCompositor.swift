//
//  CustomVideoCompositor.swift
//  CustomVideoCompositor
//
//  Created by Clay Garrett on 11/16/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class CustomVideoCompositor: NSObject, AVVideoCompositing {
    
    var duration: CMTime?
    
    var sourcePixelBufferAttributes: [String : Any]? {
        get {
            return ["\(kCVPixelBufferPixelFormatTypeKey)": kCVPixelFormatType_32BGRA]
        }
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] {
        get {
            return ["\(kCVPixelBufferPixelFormatTypeKey)": kCVPixelFormatType_32BGRA]
        }
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // do anything in here you need to before you start writing frames
    }
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        // called for every frame
        // assuming there's a single video track. account for more complex scenarios as you need to
        let buffer = request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)
        let instruction = request.videoCompositionInstruction
        
        // if we have our expected instructions
        if let inst = instruction as? WatermarkCompositionInstruction, let image = inst.watermarkImage, let frame = inst.watermarkFrame  {
            // lock the buffer, create a new context and draw the watermark image
            CVPixelBufferLockBaseAddress(buffer!, CVPixelBufferLockFlags.readOnly)
            let newContext = CGContext.init(data: CVPixelBufferGetBaseAddress(buffer!), width: CVPixelBufferGetWidth(buffer!), height: CVPixelBufferGetHeight(buffer!), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer!), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            newContext?.draw(image, in: frame)
            CVPixelBufferUnlockBaseAddress(buffer!, CVPixelBufferLockFlags.readOnly)
        }
        request.finish(withComposedVideoFrame: buffer!)
    }
    
    func cancelAllPendingVideoCompositionRequests() {
        // anything you want to do when the compositing is canceled
    }
}
