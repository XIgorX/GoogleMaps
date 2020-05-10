//
//  AppDelegate.swift
//  GoogleMapsAPISample
//
//  Created by Igor Danilchenko on 07/03/2020.
//  Copyright © 2020 Igor Danilchenko. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        GMSServices.provideAPIKey(key)
        GMSPlacesClient.provideAPIKey(key)
        
        return true
    }
    
}

