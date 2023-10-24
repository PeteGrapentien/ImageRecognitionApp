//
//  Buffer.swift
//  PhotoUpload
//
//  Created by Peter Grapentien on 10/23/23.
//

import UIKit
import Foundation
import AVFoundation
import Vision

class VideoBuffer: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var requests = [VNRequest]()
    
    func setRequests(inputRequests: [VNRequest]) {
        self.requests = inputRequests
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}
