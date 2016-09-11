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


enum DependencyTags: Int, DependencyTagConvertible {
    case Hardcoded
    case Dummy
}

// MARK: Dependency Container for Providers
func configure(container dip: DependencyContainer) {
    
    // Register the NetworkLayer, same for everyone here (but we have the ability to register a different one for a specific WebService if we wanted to)
    dip.register(.singleton) { URLSessionNetworkLayer(baseURL: "http://swapi.co/api/")! as NetworkLayer }

    if FAKE_PERSONS {
        
        // 1) Register fake persons provider
        //Here we use constructor injection for one of the dependencies property injection for another, and we provide dependencies manually
        dip.register() { FakePersonsProvider(dummyProvider: DummyPilotProvider()) as PersonProviderAPI }
            .resolvingProperties { (_, resolved: PersonProviderAPI) in
                //here we resolve optional dependencies
                //see what happens when you comment this out
                (resolved as! FakePersonsProvider).plistProvider = PlistPersonProvider(plist: "mainPilot")
        }
        
    } else {
        
        // 1) Register the SWAPIPersonProvider (that hits the real swapi.co WebService)
        // Here we use constructor injection again, but let the container to resolve dependency for us
        dip.register() { SWAPIPersonProvider(webService: try dip.resolve()) as PersonProviderAPI }

    }
    
    if FAKE_STARSHIPS {

        // 2) Register fake starships provider
        
        //Here we register different implementations for the same protocol using tags
        dip.register(tag: DependencyTags.Hardcoded) { HardCodedStarshipProvider() as StarshipProviderAPI }
        
        //Here we register factory that will require a runtime argument
        dip.register(tag: DependencyTags.Dummy) { DummyStarshipProvider(pilotName: $0) as StarshipProviderAPI }
        
        //Here we use constructor injection, but instead of providing dependencies manually container resolves them for us
        dip.register() {
            FakeStarshipProvider(
                dummyProvider: try dip.resolve(tag: DependencyTags.Dummy, arguments: "Main Pilot"),
                hardCodedProvider: try dip.resolve(tag: DependencyTags.Hardcoded)) as StarshipProviderAPI
        }
        
    } else {
        
        // 2) Register the SWAPIStarshipProvider (that hits the real swapi.co WebService)
        // Here we use constructor injection again, but let the container to resolve dependency for us
        dip.register() { SWAPIStarshipProvider(webService: try dip.resolve()) as StarshipProviderAPI }

    }
    
}
