//
//  DependencyContainers.swift
//  Dip
//
//  Created by Olivier Halligon on 10/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import Dip

// MARK: Configuration

/* Change this to toggle between real and fake data */
private let FAKE_PERSONS = false
private let FAKE_STARSHIPS = false
/* ---- */



// MARK: Dependency Container for WebServices & NetworkLayer
let wsDependencies = DependencyContainer<WebService>() { dip in
    
    // Register the NetworkLayer, same for everyone here (but we have the ability to register a different one for a specific WebService if we wanted to)
    dip.register(instance: URLSessionNetworkLayer(baseURL: "http://swapi.co/api/")! as NetworkLayer)
    
}



// MARK: Dependency Container for Providers
let providerDependencies = DependencyContainer<Int>() { dip in
    
    if FAKE_PERSONS {
        
        // 1) Register the PersonProviderAPI singleton, one generic and one specific for a specific personID
        dip.register(instance: DummyPilotProvider() as PersonProviderAPI)
        dip.register(0, instance: PlistPersonProvider(plist: "mainPilot") as PersonProviderAPI)
        
    } else {
        
        // 1) Register the SWAPIPersonProvider (that hits the real swapi.co WebService)
        dip.register(instance: SWAPIPersonProvider() as PersonProviderAPI)

    }
    
    if FAKE_STARSHIPS {

        // 2) Register the StarshipProviderAPI factories, one generic and one specific for a specific starshipID
        dip.register() { HardCodedStarshipProvider() as StarshipProviderAPI }
        dip.register(0) { DummyStarshipProvider(pilotName: "Main Pilot") as StarshipProviderAPI }
        
    } else {
        
        // 2) Register the SWAPIStarshipProvider (that hits the real swapi.co WebService)
        dip.register(instance: SWAPIStarshipProvider() as StarshipProviderAPI)

    }
    
}
