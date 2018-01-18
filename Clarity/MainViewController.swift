//
//  MainViewController.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var shutterButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func addConcept(_ sender: AnyObject) {
        NSLog("Add concept")
    }
}
