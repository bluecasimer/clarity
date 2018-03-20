/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Application preview view.
*/

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
