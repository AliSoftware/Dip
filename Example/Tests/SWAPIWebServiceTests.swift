import UIKit
import XCTest
import Dip


var dip = DependencyContainer<String>()

//let p1 = ["name": "John Doe", "mass": "72", "height": "172", "eye_color": "brown", "hair_color": "black"]
//let p2 = ["name": "Jane Doe", "mass": "63", "height": "167", "eye_color": "blue", "hair_color": "red"]
//
//class SWAPIWebServiceTests: XCTestCase {
//    
//    // MARK: - Mock object used for tests
//    
//    struct NetworkMock : NetworkLayer {
//        let fakeData: NSData?
//        
//        init(json: AnyObject) {
//            do {
//                fakeData = try NSJSONSerialization.dataWithJSONObject(json, options: [])
//            } catch {
//                fakeData = nil
//            }
//        }
//        
//        func fetchURL(url: NSURL, completion: NSData? -> Void) {
//            completion(fakeData)
//        }
//    }
//    
//    // MARK: - Test Suite
//    
//    override func setUp() {
//        super.setUp()
//        
//        dip.reset()
//        dip.register(instance: SWAPIPersonFactory() as PersonFactoryAPI)
//        dip.register(instance: JSONSerializer() as SerializerAPI)
//    }
//    
//    func testFetchPersons() {
//        let mock = NetworkMock(json: ["results":[p1,p2]])
//        dip.register(instance: mock as NetworkLayer)
//        
//        let ws = SWAPIWebService()
//        ws.fetch { persons in
//            XCTAssertNotNil(persons)
//            XCTAssertEqual(persons?.count, 2)
//            
//            XCTAssertEqual(persons?[0].name, "John Doe")
//            XCTAssertEqual(persons?[0].mass, 72)
//            XCTAssertEqual(persons?[0].height, 172)
//            XCTAssertEqual(persons?[0].eyesColor, "brown")
//            XCTAssertEqual(persons?[0].hairColor, "black")
//            
//            XCTAssertEqual(persons?[1].name, "Jane Doe")
//            XCTAssertEqual(persons?[1].mass, 63)
//            XCTAssertEqual(persons?[1].height, 167)
//            XCTAssertEqual(persons?[1].eyesColor, "blue")
//            XCTAssertEqual(persons?[1].hairColor, "red")
//        }
//    }
//    
//    func testFetchOnePerson() {
//        let mock = NetworkMock(json: p1)
//        dip.register(instance: mock as NetworkLayer)
//        
//        let ws = SWAPIWebService()
//        ws.fetch(1) { person in
//            XCTAssertNotNil(person)
//            XCTAssertEqual(person?.name, "John Doe")
//            XCTAssertEqual(person?.mass, 72)
//            XCTAssertEqual(person?.height, 172)
//            XCTAssertEqual(person?.eyesColor, "brown")
//            XCTAssertEqual(person?.hairColor, "black")
//        }
//    }
//    
//    func testFetchInvalidPerson() {
//        let json = ["error":"whoops"]
//        let mock = NetworkMock(json: json)
//        dip.register(instance: mock as NetworkLayer)
//        
//        let ws = SWAPIWebService()
//        ws.fetch(12) { person in
//            XCTAssertNil(person)
//        }
//    }
//}
