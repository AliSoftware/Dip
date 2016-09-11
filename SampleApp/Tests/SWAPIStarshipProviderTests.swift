//
//  SWAPIStarshipProviderTests.swift
//  Dip
//
//  Created by Olivier Halligon on 11/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import XCTest
import Dip

class SWAPIStarshipProviderTests: XCTestCase {
    let fakeShip1: [String: Any] = ["name": "Falcon", "model": "Fighter", "manufacturer": "Fake Industries", "crew": "7", "passengers": "15",
        "pilots": ["http://people/1/", "http://people/9"], "url": "http://starship/4"]
    let fakeShip2: [String: Any] = ["name": "Voyager", "model": "Cargo", "manufacturer": "Fake Industries", "crew": "18", "passengers": "150",
        "pilots": ["http://people/2/", "http://people/3"], "url": "http://starship/31"]
    
    override func setUp() {
        super.setUp()
        
        wsDependencies.reset()
    }
    
    func testFetchStarshipIDs() {
        let mock = NetworkMock(json: ["results": [fakeShip1, fakeShip2]])
        wsDependencies.register(.singleton) { mock as NetworkLayer }
        
        let provider = SWAPIStarshipProvider(webService: try! wsDependencies.resolve())
        provider.fetchIDs { shipIDs in
            XCTAssertNotNil(shipIDs)
            XCTAssertEqual(shipIDs.count, 2)
            
            XCTAssertEqual(shipIDs[0], 4)
            XCTAssertEqual(shipIDs[1], 31)
        }
    }
    
    func testFetchOneStarship() {
        
        let mock = NetworkMock(json: fakeShip1)
        wsDependencies.register(.singleton) { mock as NetworkLayer }
        
        let provider = SWAPIStarshipProvider(webService: try! wsDependencies.resolve())
        provider.fetch(id: 1) { starship in
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
        wsDependencies.register(.singleton) { mock as NetworkLayer }
        
        let provider = SWAPIStarshipProvider(webService: try! wsDependencies.resolve())
        provider.fetch(id: 12) { starship in
            XCTAssertNil(starship)
        }
    }
}
