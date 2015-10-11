//
//  SWAPIStarshipProviderTests.swift
//  Dip
//
//  Created by Olivier Halligon on 11/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import XCTest

class SWAPIStarshipProviderTests: XCTestCase {
    let fakeShip1 = ["name": "Falcon", "model": "Fighter", "manufacturer": "Fake Industries", "crew": "7", "passengers": "15",
        "pilots": ["stub://people/1/", "stub://people/9"], "url": "stub://starship/4"]
    let fakeShip2 = ["name": "Voyager", "model": "Cargo", "manufacturer": "Fake Industries", "crew": "18", "passengers": "150",
        "pilots": ["stub://people/2/", "stub://people/3"], "url": "stub://starship/31"]
    
    override func setUp() {
        super.setUp()
        
        wsDependencies.reset()
    }
    
    func testFetchStarshipIDs() {
        let mock = NetworkMock(json: ["results": [fakeShip1, fakeShip2]])
        wsDependencies.register(.StarshipWS, instance: mock as NetworkLayer)
        
        let provider = SWAPIStarshipProvider()
        provider.fetchIDs { shipIDs in
            XCTAssertNotNil(shipIDs)
            XCTAssertEqual(shipIDs.count, 2)
            
            XCTAssertEqual(shipIDs[0], 4)
            XCTAssertEqual(shipIDs[1], 31)
        }
    }
    
    func testFetchOneStarship() {
        
        let mock = NetworkMock(json: fakeShip1)
        wsDependencies.register(.StarshipWS, instance: mock as NetworkLayer)
        
        let provider = SWAPIStarshipProvider()
        provider.fetch(1) { starship in
            XCTAssertNotNil(starship)
            XCTAssertEqual(starship?.name, "Falcon")
            XCTAssertEqual(starship?.model, "Fighter")
            XCTAssertEqual(starship?.manufacturer, "Fake Industries")
            XCTAssertEqual(starship?.crew, 7)
            XCTAssertEqual(starship?.passengers, 15)
            XCTAssertNotNil(starship?.pilotIDs)
            XCTAssertEqual(starship?.pilotIDs[0], 1)
            XCTAssertEqual(starship?.pilotIDs[1], 9)
        }
    }
    
    func testFetchInvalidStarship() {
        let json = ["error":"whoops"]
        let mock = NetworkMock(json: json)
        wsDependencies.register(.StarshipWS, instance: mock as NetworkLayer)
        
        let provider = SWAPIStarshipProvider()
        provider.fetch(12) { starship in
            XCTAssertNil(starship)
        }
    }
}
