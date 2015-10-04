//
//  AppDelegate.swift
//  DipSampleApp
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit
import Dip

enum PersonFormatterTags : String {
    case MassHeight
    case EyesHair
}

private let _dependencies: Void = {
    Dependency.register(instance: SWAPIWebService() as WebServiceAPI)
    Dependency.register(instance: SWAPIPersonFactory() as PersonFactoryAPI)
    Dependency.register(instance: JSONSerializer() as SerializerAPI)
    Dependency.register(PersonFormatterTags.MassHeight.rawValue, instance: MassHeightFormatter() as PersonFormatterAPI)
    Dependency.register(PersonFormatterTags.EyesHair.rawValue, instance: EyesHairFormatter() as PersonFormatterAPI)
    }()


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }
}
