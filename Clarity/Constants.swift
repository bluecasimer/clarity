//
//  Constants.swift
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

import Foundation
import UIKit

let ImageProcessingDidFinish: Notification.Name = Notification.Name("ImageProcessingDidFinish")
let APIKeyUserDefaultsKey = "CAIAPIKey"

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
