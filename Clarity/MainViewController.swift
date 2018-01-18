//
//  MainViewController.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var conceptTextField: UITextField!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var shutterButton: UIButton!

    override func viewWillAppear(_ animated: Bool) {
        conceptTextField.isHidden = true
        conceptTextField.alpha = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    // MARK: NotificationHandlers
    @objc func handleKeyboardWillHide(notification: Notification) {
        conceptTextField.alpha = 0
        //        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        //        }
    }

    @objc func handleKeyboardWillShow(notification: Notification) {
        conceptTextField.isHidden = false 
        UIView.animate(withDuration: 0.4) {
            self.conceptTextField.alpha = 1
        }
//        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
//        }
    }

    @IBAction func addConcept(_ sender: AnyObject) {
        conceptTextField.becomeFirstResponder();
    }
}
