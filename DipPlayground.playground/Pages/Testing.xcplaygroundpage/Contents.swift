//: [Previous: Containers Collaboration](@previous)

//import XCTest
import Dip

let container = DependencyContainer()

/*:

### Testing
 
 If you use Dependency Injection patterns like contructor and property injection it will be much easier
 to unit test your components. When it comes to integration tests you may want to mock some real services.
 In these tests you can register mock implementation in the container and it will be injected instead of the real implementation.

Dip is convenient to use for testing. Here is s simple example of how you can write tests with Dip.

> That's a very simple example just to demonstrate use of Dip in tests, not how you should or should not test your code in general.
You can learn more about testing based on state verification vs behavior verification [here](http://martinfowler.com/articles/mocksArentStubs.html).
 
> XCTest is not supported by playgrounds so to be able to compile this page we commented out XCTest specific code.
*/

protocol ServiceType {
    func doSomething()
}

class RealService: ServiceType {
    func doSomething() {
        //do something real
    }
}

class Client {
    var service: ServiceType!
    
    func callService() {
        service.doSomething()
    }
}

/*:
Instead of the real `Service` implementation, provide a _fake_ implementation with test hooks that you need:
*/

class FakeService: ServiceType {
    var doSomethingCalled = false
    
    func doSomething() {
        doSomethingCalled = true
    }
    
    init() {}
}

/*:
 Somewhere in your production code you register real implementations:
 */
func configure(container: DependencyContainer) {
    container.register { RealService() as ServiceType }
    container.register { Client() }
        .resolvingProperties { container, client in
            client.service = try container.resolve()
    }
}

class MyTests/*: XCTestCase*/ {
    
    /*override*/ func setUp() {
        //super.setUp()

/*:
 Reset container configuration to normal state:
*/
        container.reset()
        configure(container: container)
    }
    
    func testThatDoSomethingIsCalled() {
        /*:
         Register fake implementation as `Service`:
         */
        container.register { FakeService() as ServiceType }
        
        let sut = try! container.resolve() as Client
        sut.callService()
        
/*:
And finally you test it was called:
*/
        let service = sut.service as! FakeService
        //XCTAssertTrue(service.doSomethingCalled)
    }
}

/*:
 You can also validate your container configuration. You can do that either in a separate test suit or when runnging application in `DEBUG` mode.
 
 During validation container will try to resolve all the definitions registered in it. If some of definitions requires runtime arguments you can provide them as arguments to `validate` method. They should exactly match types of arguments required by factories. Multiple arguments for the single factory should be grouped in a tuple. If you don't provide arguments validation will fail.
 */
container.register { (url: NSURL, port: Int) in ServiceImp4(name: "1", baseURL: url, port: port) as Service }
try! container.validate((NSURL(string: "https://github.com/AliSoftware/Dip")!, 80))

do {
    try container.validate()
}
catch {
    print(error)
}



