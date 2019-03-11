//
//  SettingsTableViewController.swift
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
