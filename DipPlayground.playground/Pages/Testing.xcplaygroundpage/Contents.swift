//: [Previous: Shared Instances](@previous)


/*:

### Testing

Dip is convenient to use for testing. Here is s simple example of how you can write tests with Dip.

__Note__: That's a very simple example just to demostrate use of Dip in tests, not how you should or should not tests your code in general. 
You can learn more about testing based on state verification vs behavior verification [here](http://martinfowler.com/articles/mocksArentStubs.html).

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
Instead of the real `Service` implementation, provide a _fake_ implementation with test hooks that you need:
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
And finally you test it was called:
*/
        XCTAssertTrue((sut.service as! FakeService).doSomethingCalled)
    }
}

