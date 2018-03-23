//
//  FrameExtractor.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    func capturedVideoFrame(image: UIImage)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    private let position = AVCaptureDevice.Position.front
    private let quality = AVCaptureSession.Preset.medium
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
            self.configured = self.configureSession()
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

    private func configureSession() -> Bool {
        guard permissionGranted else { return false }

        // Set up capture session and add video input
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return false }

        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return false }

        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        } else {
            print("Could not add video device input to the session")
            return false
        }

        // Set up AVCaptureVideoDataOutput for frame extraction.
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

