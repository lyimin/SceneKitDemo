//
//  AppDelegate.swift
//  SceneKitDemo
//
//  Created by Eamon Liang on 2022/1/27.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.isUserInteractionEnabled = true
        window?.rootViewController       = Display3DViewController()
        window?.makeKeyAndVisible()
        
        return true
    }

}

