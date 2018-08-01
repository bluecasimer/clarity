//
//  SettingsTableViewController.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var apiKeyTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyTextField.delegate = self

        if let apiKey = UserDefaults.standard.string(forKey: APIKeyUserDefaultsKey) {
            apiKeyTextField.text = apiKey
        } else {
            apiKeyTextField.placeholder = "Add your API Key"
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return 1
        }
    }

    // MARK: - UITextView Delegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let apiKey = textField.text {
            UserDefaults.standard.set(apiKey, forKey: APIKeyUserDefaultsKey)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
