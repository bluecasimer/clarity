//
//  CustomPredictionTableViewCell.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit

class CustomPredictionTableViewCell: UITableViewCell {

        @IBOutlet weak var nameLabel: UILabel!
        @IBOutlet weak var scoreLabel: UILabel!
        @IBOutlet weak var backgroundPadView: UIView!

        override func awakeFromNib() {
            super.awakeFromNib()
            backgroundPadView.layer.cornerRadius = 2.0
        }

        func setScoreValue(score: Float) {
            self.scoreLabel.text = String(format: "%.3f", score)
        }
}
