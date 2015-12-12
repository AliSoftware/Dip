//: [Previous: Circular Dependencies](@previous)

import Dip
import UIKit

/*:
### Shared Instances

The Singleton pattern is probably the most debatable and abused pattern in Cocoa development (and probably in programming in general). It's probably the first thing that you will hear from a candidate developer on interview when you ask about Cocoa patterns (the other one will be a delegate).

The problem with singleton is not that it's a worst pattern. The problem is that developers use it to solve problems that do not require it at all. Another problem is that it's very easy to be tempted by this pattern cause it's very easy to implement and use - import file and call `sharedInstance`. But that leads to all kinds of problems:

- First - singleton is a shared mutable state. And the worst thing is that it's a _mutable_ state.
- Second - singleton tigthly couple components of your system.
- Third - it limits your code flexibility.

Dip supports singletons, but it reduces cost of using them. Their singleton nature is managed by the _Container_ and defined only by the _Definitions_ that you register, not by concrete implementations of your classes.

- No need for calls to `sharedInstance` in your code anymore. Instead you get the instance from the _Container_ by resolving a protocol.
- You can easyly change concrete implementations without the rest of your system even notice that something changed.
- Also it's easy to test - you just register another object in your tests. Even if you still want to use a singleton in your system.

Those features you got when using Dip limits tight coupling in your code and gives you back your code flexibility.

Probably the most common example is using a singleton in the network layer or "API client".
*/

class ApiClientSingleton {
  static let sharedInstance = ApiClientSingleton()
  private init() {}
  // Typically a method that makes a GET request on your API
  func get(path: String, completion:()->()) {}
}

class MyViewControllerWithSingleton: UIViewController {
  override func viewDidAppear(amimated: Bool) {
    super.viewDidAppear(amimated)
    ApiClientSingleton.sharedInstance.get("/users") { /* refresh your UI */ }
  }
}

/*:
Sure, this is very easy to code indeed. And nothing bad so far.

But probably if you wrote a unit test or integration test for that code first, you would have noticed a problem earilier. How you test that code? And how you ensure that your tests are idenpendent of the API client's state from the previous test?
Of cource you can work around all of the problems and the fact that `ApiClient` is a singleton, reset it's state somehow, or mock a class so that it will not return a singleton instance. But look - a moment before the singleton was your best friend and now you are fighting against it.

Think - why do you want API client to be a singleton in a first place? To queue or throttle requests? Then do your queue or throttler a singleton, not an API client. Or is there any other reason. Most likely API client itself does not have a requirement to have one and only one instance during the lifecycle of your application. Imagine that in the future we need two API Clients, because you now have to address two different servers & plaforms? Imposing that singleton restricts now your flexibility a lot.

Instead, inject API client in view controller with property injection or constructor injection.
*/

protocol ApiClientProtocol {
  func get(path: String, completion:()->())
}

class ApiClient: ApiClientProtocol {
  
  private struct ApiScheduler {
    /* … */
  }
  
  private let scheduler = ApiScheduler()
  
  init(){}
  
  func get(path: String, completion:()->()) {}
}

class MyViewController: UIViewController {
  var apiClient: ApiClientProtocol!
  
  override func viewDidAppear(amimated: Bool) {
    super.viewDidAppear(amimated)
    apiClient.get("path") {}
  }
  
  convenience init(apiClient: ApiClientProtocol) {
    self.init()
    self.apiClient = apiClient
  }
  
  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

//inject with constructor
let viewController = MyViewController(apiClient: ApiClient())
//or with property
viewController.apiClient = ApiClient()

/*:
With Dip this code can look like this:
*/

let container = DependencyContainer { container in
    container.register { ApiClient() as ApiClientProtocol }
}

class DipViewController: UIViewController {
    var apiClient: ApiClientProtocol!
    
    override func viewDidAppear(amimated: Bool) {
        super.viewDidAppear(amimated)
        apiClient.get("path") {}
    }
    
    convenience init(dependencies: DependencyContainer) {
        self.init()
        self.apiClient = try! dependencies.resolve() as ApiClientProtocol
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

var dipController = DipViewController(dependencies: container)

/*:
Of cource `DependencyContainer` should not be a singleton too. Instead, inject it to objects that need to access it. And use a protocol for that. For example if your view controller needs to access API client, it does not need a reference to `DependencyContainer`, it only needs a reference to _something_ that can provide it an API client instance.
*/

protocol ApiClientProvider {
  func apiClient() -> ApiClientProtocol
}

extension DependencyContainer: ApiClientProvider {
  func apiClient() -> ApiClientProtocol {
    return try! self.resolve() as ApiClientProtocol
  }
}

extension DipViewController {
    convenience init(apiClientProvider: ApiClientProvider) {
        self.init()
        self.apiClient = apiClientProvider.apiClient()
    }
}

dipController = DipViewController(apiClientProvider: container)

/*:
This way you also does not depend directly on Dip. Instead you provide a boundary between Dip — that you don't have control of — and your source code. So when something chagnes in Dip, you update only the boundary code.

Dependency injection is a pattern as well as singleton. And any pattern can be abused. DI can be use in a [wrong way]((http://www.loosecouplings.com/2011/01/dependency-injection-using-di-container.html)), container can easily become a [service locator](http://blog.ploeh.dk/2010/02/03/ServiceLocatorisanAnti-Pattern/). That's why if you adopt DI in one part of your system it does not mean that you should inject everything and everywhere. The same with using protocols instead of concrete implementations. For every tool there is a right time and the same way as singleton can harm you the same way DI and protocols abuse can make your code unnececerry complex.

*/

//: [Next: Testing](@next)


