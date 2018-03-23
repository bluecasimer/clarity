//
//  Constants.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import Foundation
import UIKit

let ImageProcessingDidFinish: Notification.Name = Notification.Name("ImageProcessingDidFinish")

extension UIColor {
    class func scoreColorGreen() -> UIColor {
        return UIColor(red: 36.0/255.0, green: 179.0/255.0, blue: 107.0/255.0, alpha: 1.0)
    }

    class func scoreColorRed() -> UIColor {
        return UIColor(red: 217.0/255.0, green: 58.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    }

    class func scoreColorYellow() -> UIColor {
        return UIColor(red: 217.0/255.0, green: 166.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    }
}
