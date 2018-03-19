//
//  Prediction.swift
//  Clarity
//
//  Created by John Sloan on 3/15/18.
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit
import Clarifai_Apple_SDK

class Prediction: NSObject {

    var isCustomConcept: Bool
    var concept: Concept

    init(isCustomConcept: Bool, concept: Concept) {
        self.isCustomConcept = isCustomConcept
        self.concept = concept
        super.init()
    }
}
