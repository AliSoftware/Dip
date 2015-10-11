import XCTest
import Dip

var wsDependencies = DependencyContainer<WebService>()

let fakePerson1 = ["name": "John Doe", "mass": "72", "height": "172", "eye_color": "brown", "hair_color": "black", "gender": "male", "starships": [], "url": "stub://people/1"]
let fakePerson2 = ["name": "Jane Doe", "mass": "63", "height": "167", "eye_color": "blue", "hair_color": "red", "gender": "female", "starships": [], "url": "stub://people/12"]

class SWAPIWebServiceTests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        wsDependencies.reset()
    }
    
    func testFetchPersons() {
        let mock = NetworkMock(json: ["results": [fakePerson1, fakePerson2]])
        wsDependencies.register(.PersonWS, instance: mock as NetworkLayer)
        
        let ws = SWAPIPersonProvider()
        ws.fetchIDs { personIDs in
            XCTAssertNotNil(personIDs)
            XCTAssertEqual(personIDs.count, 2)
            
            XCTAssertEqual(personIDs[0], 1)
            XCTAssertEqual(personIDs[1], 12)
        }
    }
    
    func testFetchOnePerson() {
        
        let mock = NetworkMock(json: fakePerson1)
        wsDependencies.register(.PersonWS, instance: mock as NetworkLayer)
        
        let ws = SWAPIPersonProvider()
        ws.fetch(1) { person in
            XCTAssertNotNil(person)
            XCTAssertEqual(person?.name, "John Doe")
            XCTAssertEqual(person?.mass, 72)
            XCTAssertEqual(person?.height, 172)
            XCTAssertEqual(person?.eyeColor, "brown")
            XCTAssertEqual(person?.hairColor, "black")
        }
    }
    
    func testFetchInvalidPerson() {
        let json = ["error":"whoops"]
        let mock = NetworkMock(json: json)
        wsDependencies.register(.PersonWS, instance: mock as NetworkLayer)
        
        let ws = SWAPIPersonProvider()
        ws.fetch(12) { person in
            XCTAssertNil(person)
        }
    }
}
