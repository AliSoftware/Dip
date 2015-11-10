//: [Previous](@previous)

import Dip
import UIKit

/*:
### Shared Instances

Singleton pattern is propbably the most debatable and abused pattern in Cocoa development (and probably in programming in general). It's probably the first thing that you will hear from a candidate developer on interview when you ask about Cocoa patterns (the other one will be a delegate).

The problem with singleton is not that it's a worst pattern. The problem is that developers use it to solve problems that do not require it at all. Another problem is that it's very easy to be tempted by this patter cause it's very easy to implement and use - import file and call `sharedInstance`. But that leads to all kinds of problems. First - singleton is a shared mutable state. And the worst thing is that it's a _mutable_ state. Second - singleton tigthly couple compoents of your system. Third - it limits your code flexibility.

Dip supports singletons but it reduces cost of using them. Their singleton nature is managed by container and defined only by definitions that you register not by concrete implementations of your classes. No more calls to `sharedInstance` in your code requeired. Instead you get the instance from container by resolving a protocol. You can easyly change concrete implementations without the rest of your system even notice that something changed. Also it's easy to test - you just register another object in your tests. Even if you still want to use singleton in your system.

Probably the most common example is using singleton in network layer or "api client".
*/

class ApiClientSingleton {
    static let sharedInstance = ApiClientSingleton()
    private init() {}
    func get(path: String, completion:()->()) {}
}

class MyViewControllerWithSingleton: UIViewController {
  override func viewDidAppear(amimated: Bool) {
    super.viewDidAppear(amimated)
    ApiClientSingleton.sharedInstance.get("/users") {}
  }
}

/*:
Very easy endeed. And nothing bad so far. Probably if you started with a unit test or integration test for that code you would notice a problem earilier. How you test that code? And how you ensure that your tests are idenpendent of the api client's state from the previous test? Of cource you can work around all of the problems and the fact that `ApiClient` is a singleton, reset it's state somehow, or mock a class so that it will return not a singleton instance. But look - few moments before a singleton was your best friend and now you are fighting against it.

Think - why you want api client to be a singleton in a first place? To queue or throttle requests? Then do your queue or throttler a singleton, not an api client. Or is there any other reason. Most likely api client itself does not have a requirement to have only one system during the whole lifecycle of application. Inject api client in view controller with property injection or constructor injection. If you need use singleton of smaller scope internally in api client, as a private implementation detail.
*/

protocol ApiClientProtocol {
    func get(path: String, completion:()->())
}

class ApiClient: ApiClientProtocol {
    
    private class ApiScheduler {
        static let sharedInstance = ApiScheduler()
        private init(){}
    }
    
    private let scheduler = ApiScheduler.sharedInstance
    
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
        self.apiClient = dependencies.resolve() as ApiClientProtocol
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
Of cource `DependencyContainer` should not be used as singleton too. Insted inject it to objects that need to access it. And use a protocol for that. For example if your view controller needs to access api client it does not need a reference to `DependencyContainer`, it only needs a reference to _something_ that can provide it an api client instance.
*/

protocol ApiClientProvider {
  func apiClient() -> ApiClientProtocol
}

extension DependencyContainer: ApiClientProvider {
  func apiClient() -> ApiClientProtocol {
    return self.resolve() as ApiClientProtocol
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
This way you also does not depend directly on Dip. Instead you provide boundary between Dip that you don't have control of and your sorce code. So when something chages in Dip you update only the boundary code.

Dependency injection is a patterns as well as singleton. And any pattern can be abused. That's why if you adopt DI in one part of your system it does not mean that you should inject everything and everywhere. The same with using protocols instead of concrete implementations. For every tool there is a right time and the same way as singleton can harm you the same way DI and protocols abuse can make your code unnececerry complex.

*/

//: [Next](@next)


