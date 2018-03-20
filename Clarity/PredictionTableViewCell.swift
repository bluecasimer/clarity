//
//  PredictionTableViewCell.swift
//  Clarity
//
//  Created by John Sloan on 3/2/18.
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit

class PredictionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var backgroundPadView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundPadView.layer.cornerRadius = 2.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setScoreValue(score: Float) {
        if (score >= 0.9) {
            // green color
            self.scoreLabel.textColor = UIColor.scoreColorGreen()
        } else if score < 0.6 {
            // red color
            self.scoreLabel.textColor = UIColor.scoreColorRed()
        } else {
            // yellow color
            self.scoreLabel.textColor = UIColor.scoreColorYellow()
        }

        let scoreText = String(format: "%.3f", score)
        self.scoreLabel.text = scoreText
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.contentView.bringSubview(toFront: scoreLabel)
        self.contentView.bringSubview(toFront: nameLabel)
        self.contentView.sendSubview(toBack: backgroundPadView)
    }

}
