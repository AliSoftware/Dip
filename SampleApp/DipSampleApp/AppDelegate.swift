//
//  AppDelegate.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit
import Dip

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let container = DependencyContainer()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        
        //This is a composition root where container is configured and all dependencies are resolved
        configure(container: container)
        
        let personProvider = try! container.resolve() as PersonProviderAPI
        let starshipProvider = try! container.resolve() as StarshipProviderAPI
        
        if let tabBarVC = self.window?.rootViewController as? UITabBarController,
            let vcs = tabBarVC.viewControllers as? [UINavigationController] {
                if let personListVC = vcs[0].topViewController as? PersonListViewController {
                    personListVC.personProvider = personProvider
                    personListVC.starshipProvider = starshipProvider
                    personListVC.loadFirstPage()
                }
                if let starshipListVC = vcs[1].topViewController as? StarshipListViewController {
                    starshipListVC.starshipProvider = starshipProvider
                    starshipListVC.personProvider = personProvider
                    starshipListVC.loadFirstPage()
                }
        }
        
        return true
    }
}
