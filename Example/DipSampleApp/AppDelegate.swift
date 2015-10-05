//
//  AppDelegate.swift
//  DipSampleApp
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit
import Dip

enum PersonFormatterTags {
    case MassHeight
    case EyesHair
}

let dip: DependencyContainer<PersonFormatterTags> = {
    let dip = DependencyContainer<PersonFormatterTags>()
    dip.register(instance: SWAPIWebService() as WebServiceAPI)
    dip.register(instance: SWAPIPersonFactory() as PersonFactoryAPI)
    dip.register(instance: JSONSerializer() as SerializerAPI)
    dip.register(PersonFormatterTags.MassHeight, instance: MassHeightFormatter() as PersonFormatterAPI)
    dip.register(PersonFormatterTags.EyesHair, instance: EyesHairFormatter() as PersonFormatterAPI)
    return dip
}()


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }
}
