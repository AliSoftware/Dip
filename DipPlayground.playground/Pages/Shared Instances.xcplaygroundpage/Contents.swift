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
  override func viewDidAppear(_ amimated: Bool) {
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
    super.viewDidAppear(_ amimated)
    apiClient.get("path") {}
  }
  
  convenience init(apiClient: ApiClientProtocol) {
    self.apiClient = apiClient
    self.init()
  }
  
  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

//inject with constructor
var viewController = MyViewController(apiClient: ApiClient())
//or with property
viewController.apiClient = ApiClient()

/*:
With Dip this code can look like this:
*/

let container = DependencyContainer()
container.register { ApiClient() as ApiClientProtocol }

//inject with constructor
viewController = try MyViewController(apiClient: container.resolve())
//or with property
viewController.apiClient = try container.resolve()

/*:
Of cource `DependencyContainer` should not be a singleton too. There is just no need for that because you never should call `DependencyContainer` from inside of your components. That will make it a [service locator antipatter]((http://blog.ploeh.dk/2010/02/03/ServiceLocatorisanAnti-Pattern/)). You may only call `DependencyContainer` from the _Composition root_ - the place where all the components are configured and wired together.

Dependency Injection is a pattern (more precisely - a set of patterns) as well as a singleton. And any pattern can be abused. DI can be used in a [wrong way]((http://www.loosecouplings.com/2011/01/dependency-injection-using-di-container.html)), container can easily become a service locator. You should carefully decide when to use DI, you should not inject everything and everywhere and define a protocol for every single class you use. For every tool there is a right time and the same way as singleton can harm you the same way DI and protocols abuse can make your code unnececerry complex.

If you want to know more about Dependency Injection in general we recomend you to read ["Dependency Injection in .Net" by Mark Seemann](https://www.manning.com/books/dependency-injection-in-dot-net). Dip was inspired by implementations of IoC container for .Net platform and shares core principles described in that book.

*/

//: [Next: Auto-wiring](@next)


