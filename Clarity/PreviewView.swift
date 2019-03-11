//
//  PreviewView.swift
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

import UIKit
import AVFoundation

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Failed to load video preview layer.")
        }
        return layer
    }
	
	var session: AVCaptureSession? {
		get {
			return videoPreviewLayer.session
		}
		set {
			videoPreviewLayer.session = newValue
		}
	}
	
    override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
}
