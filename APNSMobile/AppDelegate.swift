//
//  AppDelegate.swift
//  APNSMobile
//
//  Created by Alex on 5/31/17.
//  Copyright © 2017 Uriphium. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static var identifier: Int?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let _ = JSONFileManager.shared
        //UserDefaults.standard.set("746705477FACD45A4F8A5DCE06D9573E8A4B27F5D0F34A1B46EB8E529E216C36", forKey: "token")
        
        return true
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let host = url.host else { return false}
        UserDefaults.standard.set(host, forKey: "token")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if let id = AppDelegate.identifier{
            UIApplication.shared.endBackgroundTask(id)
            AppDelegate.identifier = nil
        }
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        AppDelegate.identifier = UIApplication.shared.beginBackgroundTask(withName: "delay_send") {
            UIApplication.shared.endBackgroundTask(AppDelegate.identifier!)
            AppDelegate.identifier = nil
        }
        
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

