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
private let FAKE_PERSONS = true
private let FAKE_STARSHIPS = true
/* ---- */


// MARK: Dependency Container for Providers
func configureContainer(dip: DependencyContainer) {
    
    // Register the NetworkLayer, same for everyone here (but we have the ability to register a different one for a specific WebService if we wanted to)
    dip.register(.Singleton) { URLSessionNetworkLayer(baseURL: "http://swapi.co/api/")! as NetworkLayer }

    if FAKE_PERSONS {
        
        // 1) Register fake persons provider
        dip.register() { FakePersonsProvider(dummyProvider: DummyPilotProvider(), plistProvider: PlistPersonProvider(plist: "mainPilot")) as PersonProviderAPI }
        
    } else {
        
        // 1) Register the SWAPIPersonProvider (that hits the real swapi.co WebService)
        dip.register() { SWAPIPersonProvider(webService: try dip.resolve()) as PersonProviderAPI }

    }
    
    if FAKE_STARSHIPS {

        // 2) Register fake starships provider
        dip.register() { FakeStarshipProvider(dummyProvider: DummyStarshipProvider(pilotName: "Main Pilot"), hardCodedProvider: HardCodedStarshipProvider()) as StarshipProviderAPI }
        
    } else {
        
        // 2) Register the SWAPIStarshipProvider (that hits the real swapi.co WebService)
        dip.register() { SWAPIStarshipProvider(webService: try dip.resolve()) as StarshipProviderAPI }

    }
    
}
