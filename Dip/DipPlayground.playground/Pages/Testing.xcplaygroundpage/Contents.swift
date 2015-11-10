//: [Previous](@previous)


/*:

### Testing

Dip is convenient to use for testing. Here is s simple example how you can write test with Dip.

__Note__: That's a very simple example just to demostrate use of Dip in tests, not how you should or should not tests your code in general. 
If you want you can learn more about testing based on state verificatin vs behavior verification [here](http://martinfowler.com/articles/mocksArentStubs.html)

*/

protocol Service {
    func doSomething()
}

class Client {
    var service: Service!
    
    func callService() {
        service.doSomething()
    }
}

import XCTest
import Dip

/*:
Instead of real `Service` implementation provide _fake_ implementation with test hooks that you need:
*/

class FakeService: Service {
    var doSomethingCalled = false
    
    func doSomething() {
        doSomethingCalled = true
    }
    
    init() {}
}

class MyTests: XCTestCase {
    var container: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        
/*:
Register fake implementation as `Service`:
*/
        container = DependencyContainer { container in
            container.register { FakeService() as Service }
        }
    }
    
    func testThatDoSomethingIsCalled() {
        let sut = Client()
        sut.service = container.resolve() as Service

        sut.callService()
        
/*:
And finally you test it:
*/
        XCTAssertTrue((sut.service as! FakeService).doSomethingCalled)
    }
}

//: [Next](@next)
