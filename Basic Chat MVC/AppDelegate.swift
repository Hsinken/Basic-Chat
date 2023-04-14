//
//  AppDelegate.swift
//  Basic Chat MVC
//
//  Created by Trevor Beaton on 2/3/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //let rData = ATCmdHelper.receiveToData("02740215\nOK")
        //print(rData)
        //let testStr = "0215" // Int 533
        let testStr = "0EC5F6E0" //Int +247854816 //LocationDegrees :24.7854816
        //let testStr = "481EFFB0" //Int +1209991088 //LocationDegrees :120.9991088
        //let testResult = ATCmdHelper.hexStringToInt32(testStr)
        let testResult = ATCmdHelper.hexStringToLocationDegrees(testStr)
        
        //let testStr = "0x42f9b6c9" //124.857
        //let testStr = "0xc2f9b6c9" //-124.857
        //let testResult = ATCmdHelper.hexStringToFloat(testStr)
        
        print(testResult ?? "Cant't conv:" + testStr)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

