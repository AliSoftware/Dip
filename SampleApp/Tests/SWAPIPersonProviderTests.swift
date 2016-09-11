//
//  SWAPIPersonProviderTests.swift
//  Dip
//
//  Created by Olivier Halligon on 11/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import XCTest
import Dip

class SWAPIPersonProviderTests: XCTestCase {
    let fakePerson1: [String : Any] = ["name": "John Doe", "mass": "72", "height": "172", "eye_color": "brown", "hair_color": "black", "gender": "male",
        "starships": ["http://starship/7/", "http://starship/15"], "url": "http://people/1"]
    let fakePerson2: [String: Any] = ["name": "Jane Doe", "mass": "63", "height": "167", "eye_color": "blue", "hair_color": "red", "gender": "female",
        "starships": ["http://starship/11/"], "url": "http://people/12"]
    
    override func setUp() {
        super.setUp()
        
        wsDependencies.reset()
    }
    
    func testFetchPersonIDs() {
        let mock = NetworkMock(json: ["results": [fakePerson1, fakePerson2]])
        wsDependencies.register(.singleton) { mock as NetworkLayer }
        
        let provider = SWAPIPersonProvider(webService: try! wsDependencies.resolve())
        provider.fetchIDs { personIDs in
            XCTAssertNotNil(personIDs)
            XCTAssertEqual(personIDs.count, 2)
            
            XCTAssertEqual(personIDs[0], 1)
            XCTAssertEqual(personIDs[1], 12)
        }
    }
    
    func testFetchOnePerson() {
        let mock = NetworkMock(json: fakePerson1)
        wsDependencies.register(.singleton) { mock as NetworkLayer }
        
        let provider = SWAPIPersonProvider(webService: try! wsDependencies.resolve())
        provider.fetch(id: 1) { person in
            XCTAssertNotNil(person)
            XCTAssertEqual(person?.name, "John Doe")
            XCTAssertEqual(person?.mass, 72)
            XCTAssertEqual(person?.height, 172)
            XCTAssertEqual(person?.eyeColor, "brown")
            XCTAssertEqual(person?.hairColor, "black")
            XCTAssertEqual(person?.gender, .Male)
            XCTAssertEqual(person?.starshipIDs.count, 2)
            XCTAssertEqual(person?.starshipIDs[0], 7)
            XCTAssertEqual(person?.starshipIDs[1], 15)
        }
    }
    
    func testFetchInvalidPerson() {
        let json = ["error":"whoops"]
        let mock = NetworkMock(json: json)
        wsDependencies.register(.singleton) { mock as NetworkLayer }
        
        let provider = SWAPIPersonProvider(webService: try! wsDependencies.resolve())
        provider.fetch(id: 12) { person in
            XCTAssertNil(person)
        }
    }
}
