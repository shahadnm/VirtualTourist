//
//  AppDelegate.swift
//  virtualTourist
//
//  Created by Shahad Almutawa on 29/05/1440 AH.
//  Copyright © 1440 Shahad Almutawa. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let dataController = DataController(modelName: "virtualTouristData")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        dataController.load()
        
        let navigationController = window?.rootViewController as! UINavigationController
        let viewController = navigationController.topViewController as! ViewController
        viewController.dataController = dataController
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }
    func saveViewContext() {
        try? dataController.viewContext.save()
    }
    
}

