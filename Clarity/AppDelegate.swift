//
//  AppDelegate.swift
//  Clarity
//
//  Copyright © 2018 Clarifai. All rights reserved.
//

import UIKit
import Clarifai_Apple_SDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var apiKey = "<<Your API Key>>"

        if apiKey == "<<Your API Key>>" {
            if let savedAPIKey = UserDefaults.standard.string(forKey: APIKeyUserDefaultsKey) {
                apiKey = savedAPIKey
            } else {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Add Your API Key", message: "For more info, go to \nhttps://clarifai.com/developer", preferredStyle: .alert)
                    alertController.addTextField(configurationHandler: { (textField) in
                        textField.placeholder = "Enter your API key"
                    })

                    let saveAction = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
                        let textField = alertController.textFields![0] as UITextField
                        if let key = textField.text {
                            UserDefaults.standard.set(key, forKey: APIKeyUserDefaultsKey)
                            Clarifai.sharedInstance().start(apiKey: key)
                        }
                    })

                    alertController.addAction(saveAction)
                    self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            UserDefaults.standard.set(apiKey, forKey: APIKeyUserDefaultsKey)
        }

        Clarifai.sharedInstance().start(apiKey: apiKey)
        return true
    }
}
