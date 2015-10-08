//
//  AppDelegate.swift
//  DipSampleApp
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit
import Dip

let dip: DependencyContainer<String> = {
    let dip = DependencyContainer<String>()

    // 1) Register the PersonProviderAPI singleton
    dip.register(instance: DummyPilotProvider() as PersonProviderAPI)
    
    // 2) Register the StarshipProviderAPI, one generic and one specific for a specific pilot
    dip.register() { DummyStarshipProvider(pilot: $0 ?? "Luke") as StarshipProviderAPI }
    dip.register("Luke Skywalker") { HardCodedStarshipProvider() as StarshipProviderAPI }

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
                    personListVC.loadPersons()
                }
                if let starshipListVC = vcs[1].topViewController as? StarshipListViewController {
                    starshipListVC.loadStarships()
                }
        }
        
        return true
    }
}
