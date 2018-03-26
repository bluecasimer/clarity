//
//  PredictionTableViewCell.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit

class PredictionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var backgroundPadView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundPadView.layer.cornerRadius = 2.0
    }

    func setScoreValue(score: Float) {
        if (score >= 0.9) {
            self.scoreLabel.textColor = UIColor.scoreColorGreen()
        } else if score < 0.6 {
            self.scoreLabel.textColor = UIColor.scoreColorRed()
        } else {
            self.scoreLabel.textColor = UIColor.scoreColorYellow()
        }
        self.scoreLabel.text = String(format: "%.3f", score)
    }
}
