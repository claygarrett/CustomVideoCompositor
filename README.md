# CustomVideoCompositor
A project to help users workaround a bug in iOS 10.0-10.1 related to AVAssetExportSession and AVVideoCompositionCoreAnimationTool

# Sample Output
![Sample Output](http://i.imgur.com/ovzm4QU.gif "Logo Title Text 1")

# Background
In iOS 10, a bug in AVFoundation was introduced that causes `AVPlayer` instances to sometimes stop showing video (while continuing to play audio). This occurs after an instance of `AVAssetExportSession` runs if it utilizes `AVVideoCompositionCoreAnimationTool`, which is commonly used to do various types compositing of images/video. One common scenario is adding a watermark on top of a video while exporting.

A workaround for this is to create your own custom video compositor that implements `AVVideoCompositing` protocol and custom compositing instructions that implement the `AVVideoCompositionInstructionProtocol` protocol. This projects demonstrates implementation of those protocols and the flow of information from the class that implements the AVAssetExportSession down to the method that renders each video frame. It is in no way meant to be a complete solution (though it should work for very simple use cases), but to help those facing this bug understand how to start solving it.

# Files of Interest

## VideoExporter.swift
Does the basic setup for getting a video export. You should already have code that does most of this. Some important lines to note here.

Set your customVideoCompositorClass to the class you created that implements `AVVideoCompositing`:

```swift
videoComposition.customVideoCompositorClass = CustomVideoCompositor.self
```    
Set up your custom instructions so your compositor knows what do do with each frame:
```swift
// build instructions
let instructionTimeRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)
// we're overlaying this on our source video. here, our source video is 1080 x 1080
// so even though our final export is 320 x 320, if we want full coverage of the video with our watermark,
// then we need to make our watermark frame 1080 x 1080
let watermarkFrame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
let instruction = WatermarkCompositionInstruction(timeRange: instructionTimeRange, watermarkImage: image!, watermarkFrame: watermarkFrame)
videoComposition.instructions = [instruction]
```

Note: make sure you cover the entire duration of the length of your video between all your instructions' Time Range. In our example, we use only one watermark image and our single instruction covers the entire duration of the video. But we could just as easily do one image for the first half and one for the second half by creating 2 separate instructions with differing time ranges.

## WatermarkCompositionInstruction.swift

This is a simple class that stores data about the necessary information to render video for a given time range. In our case, it holds a watermark image and a frame for positioning/sizing that image.

## CustomVideoCompositor.swift

This file actually does the rendering. All of the rendering logic exists here:

```swift
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
```

# Other potential solutions

Ethan on Stack Overflow has another pretty great solution on how to do this using CIFilters: http://stackoverflow.com/a/39786820/1120513 Would be a great solution if you're just trying to add a watermark or do something that CIFilters can handle on their own.

# Bug references:

http://stackoverflow.com/questions/39760147/ios-10-avplayerlayer-doesnt-show-video-after-using-avvideocompositioncoreanima/39780044?noredirect=1#comment68493623_39780044

https://forums.developer.apple.com/thread/62521
