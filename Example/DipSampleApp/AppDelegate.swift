//
//  AppDelegate.swift
//  DipSampleApp
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit
import Dip

let dip: DependencyContainer<Int> = {
    let dip = DependencyContainer<Int>()

    // 1) Register the PersonProviderAPI singleton, one generic and one specific for a specific personID
    dip.register(instance: DummyPilotProvider() as PersonProviderAPI)
    let mainPersonProvider = PlistPersonProvider(plist: "mainPilot")
    dip.register(0, instance: mainPersonProvider as PersonProviderAPI)
    
    // 2) Register the StarshipProviderAPI factories, one generic and one specific for a specific starshipID
    dip.register() { HardCodedStarshipProvider() as StarshipProviderAPI }
    let pilotName = mainPersonProvider.people[0].name
    dip.register(0) { DummyStarshipProvider(pilotName: pilotName) as StarshipProviderAPI }

    return dip
}()


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        if let tabBarVC = self.window?.rootViewController as? UITabBarController,
            let vcs = tabBarVC.viewControllers as? [UINavigationController] {
                if let personListVC = vcs[0].topViewController as? PersonListViewController {
                    personListVC.fetchAllObjects()
                }
                if let starshipListVC = vcs[1].topViewController as? StarshipListViewController {
                    starshipListVC.fetchAllObjects()
                }
        }
        
        return true
    }
}
