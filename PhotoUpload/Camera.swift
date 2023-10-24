//
//  Camera.swift
//  PhotoUpload
//
//  Created by Peter Grapentien on 10/23/23.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision

class Camera: ObservableObject {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var videoDataOutput = AVCaptureVideoDataOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var textPrediction = "No Car"
    @Published var cameraButtonColor: CGColor = UIColor.red.cgColor
    
    var requests = [VNRequest]()
    
    var buffer = VideoBuffer()
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.setupCamera()
                    return
                }
            }
        case .denied:
            //Handle via alert
            return
        default:
            return
        }
    }
    
    func startSession() {
        self.session.startRunning()
    }
    
    func stopSession() {
        self.session.stopRunning()
    }
    
    func setupMlModel() {
        guard let modelURL = Bundle.main.url(forResource: "SubaruSideViewClassifier 1", withExtension: "mlmodelc") else {
            print(NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"]))
            return
        }
        do {
            let visionModel =  try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    if let results = request.results {
                        self.toggleButtonColor(observations: results)
                    }
                })
            })
            
            self.requests = [objectRecognition]
        } catch {
            print("Model setup failed with error: " + error.localizedDescription)
        }
    }
    
    func toggleButtonColor(observations: [VNObservation]) {
        //This only loops through the recognized objects. VNClassificationObservation contains general classification information
        //VNRecognizedObjectObservation is for recognized objects
        for observation in observations where observation is VNClassificationObservation {
            let confidenceString = observation.confidence.description.prefix(5)
            let confidence = (confidenceString as NSString).floatValue
            print(confidence)
            if confidence > 9.85 {
                print(">>>>Subaru")
                self.textPrediction = "Car"
                self.cameraButtonColor = UIColor.blue.cgColor
            }
        }
    }
    
    func setupCamera() {
        self.setupMlModel()
        
        do {
            self.session.beginConfiguration()
            session.sessionPreset = .vga640x480
            
            let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
            
            //Add guard let here instead of force
            let input = try AVCaptureDeviceInput(device: device!)
            
            let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                self.buffer.setRequests(inputRequests: self.requests)
                self.videoDataOutput.setSampleBufferDelegate(buffer, queue: videoDataOutputQueue)
            } else {
                print("Can't add output")
                return
            }
            
            let captureConnection = self.videoDataOutput.connection(with: .video)
            captureConnection?.isEnabled = true
            do {
                try device?.lockForConfiguration()
                
            } catch {
                print(error)
            }
            
            self.session.commitConfiguration()
            
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    
    //STREAT CONTENT INTO ML MODEL FROM HERE
    
    @ObservedObject var camera: Camera
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)

        camera.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
