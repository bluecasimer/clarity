//
//  FrameExtractor.swift
//  Clarity
//
//  Copyright © 2019 Clarifai
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  Adapted from Boris Ohayon https://medium.com/ios-os-x-development/ios-camera-frames-extraction-d2c0f80ed05a

import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    func capturedVideoFrame(image: UIImage)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    private let position = AVCaptureDevice.Position.front
    private let quality = AVCaptureSession.Preset.hd1280x720
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let context = CIContext()
    private var configured = false

    let captureSession = AVCaptureSession()
    weak var delegate: FrameExtractorDelegate?

    override init() {
        super.init()
    }

    func startExtracting() {
        checkPermission { (granted) in
            self.permissionGranted = granted
        }
        sessionQueue.async { [unowned self] in
            self.configured = self.configureSessionForVideo()
            self.captureSession.startRunning()
        }
    }

    // MARK: AVSession configuration
    private func checkPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
             completion(true)
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
                completion(granted)
                self.sessionQueue.resume()
            }
        default:
            completion(false)
        }
    }

    private func configureSessionForVideo() -> Bool {
        guard permissionGranted else { return false }

        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return false }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return false }
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        } else {
            print("Could not add video device input to the session")
            return false
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return false }
        captureSession.addOutput(videoOutput)
        guard let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video) else { return false }
        guard connection.isVideoOrientationSupported else { return false }
        guard connection.isVideoMirroringSupported else { return false }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
        return true
    }

    private func selectCaptureDevice() -> AVCaptureDevice? {
        var defaultVideoDevice: AVCaptureDevice?
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            defaultVideoDevice = dualCameraDevice
        } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            defaultVideoDevice = backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            defaultVideoDevice = frontCameraDevice
        }
        return defaultVideoDevice
    }

    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: Public methods
    func stopFrameExtraction() {
        if !configured {
            return
        }
        sessionQueue.async { [unowned self] in
            self.captureSession.stopRunning()
        }
    }

    func startFrameExtraction() {
        if !configured {
            return
        }
        sessionQueue.async { [unowned self] in
            self.captureSession.startRunning()
        }
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.capturedVideoFrame(image: image)
        }
    }
}

