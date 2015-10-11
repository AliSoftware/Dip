//
//  AppDelegate.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        if let tabBarVC = self.window?.rootViewController as? UITabBarController,
            let vcs = tabBarVC.viewControllers as? [UINavigationController] {
                if let personListVC = vcs[0].topViewController as? PersonListViewController {
                    personListVC.loadFirstPage()
                }
                if let starshipListVC = vcs[1].topViewController as? StarshipListViewController {
                    starshipListVC.loadFirstPage()
                }
        }
        
        return true
    }
}
