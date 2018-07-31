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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Clarifai.sharedInstance().start(apiKey: "<<Your API Key>>")

        return true
    }
}
