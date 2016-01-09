//: [Previous: Shared Instances](@previous)

import UIKit
import Dip

let container = DependencyContainer()
/*:

### Auto-Injection

If you follow Single Responsibility Principle chances are very high that you will end up with more than two collaborating components in your system. Let's say you have a component that depends on few others. Using _Dip_ you can register all of the dependencies in a container as well as that component itself and register a factory that will create that component and feed it with the dependencies resolving them with a container:
*/

protocol Service: class {
    var logger: Logger? { get set }
    var tracker: Tracker? { get set }
}

class ServiceImp: Service {
    var logger: Logger?
    var tracker: Tracker?
}

container.register() { TrackerImp() as Tracker }
container.register() { LoggerImp() as Logger }

container.register() { ServiceImp() as Service }
    .resolveDependencies { container, service in
        service.logger = try! container.resolve() as Logger
        service.tracker = try! container.resolve() as Tracker
}

let service = try! container.resolve() as Service
service.logger
service.tracker

/*:
Not bad so far. Though that `resolveDependencies` block looks heavy. It would be cool if we can get rid of it. Alternatively you can use _constructor injection_ here, which is actually more prefereable by default but not always possible (see [circular dependencies](Circular%20dependencies)).
Now let's say that you have a bunch of components in your app that require `Logger` or `Tracker` too. You will need to resolve them in a factory for each component again and again. That can be a lot of boilerplate code, simple but still duplicated.

That is one of the scenarios when auto-injection can be usefull. It works with property injection and with it the previous code will transform to this:
*/

class AutoInjectedServiceImp: Service {
    private var injectedLogger = Injected<Logger>()
    var logger: Logger? { get { return injectedLogger.value } set { injectedLogger.value = newValue } }
    
    private var injectedTracker = Injected<Tracker>()
    var tracker: Tracker? { get { return injectedTracker.value } set { injectedTracker.value = newValue } }
}

container.register() { AutoInjectedServiceImp() as Service }

let autoInjectedService = try! container.resolve() as Service
autoInjectedService.logger
autoInjectedService.tracker

/*:
The same you can do if you already have an instance of service and just want to resolve its dependencies:
*/

let providedService = AutoInjectedServiceImp()
container.resolveDependencies(providedService)
providedService.logger
providedService.tracker

/*:
As you can see we added two private properties to our implementation of `Service` - `injectedLogger` and `injectedTracker`. Their types are `Injeceted<Logger>` and `Injected<Tracker>` respectively. Note that we've not just defined them as properties of those types, but defined them with some initial value. `Injected<T>` is a simple _wrapper class_ that wraps value of generic type and provides read-write access to it with `value` property. This property is defined as optional, so that when we create instance of `Injected<T>` it will have `nil` in its value. There is also another wrapper - `InjectedWeak<T>` - which in contrast to `Injected<T>` holds a week reference to its wrapped object, thus requiring it to be a _reference type_ (or `AnyObject`), when `Injected<T>` can also wrap value types (or `Any`).

What is happening under the hood is that after concrete instance of resolved type is created (`Service` in that case), container will iterate through its properties using `Mirror`. For each of the properties wrapped with `Injected<T>` or `InjectedWeak<T>` it will search a definition that can be used to create an instance of wrapped type and use it to create and inject a concrete instance in a `value` property of a wrapper. The fact that wrappers are _classes_ or _reference types_ makes it possible at runtime to inject dependency in instance of resolved type.

Another example of using auto-injection is circular dependencies. Let's say you have a `Server` and a `ServerClient` both referencing each other. Standard way to register such components in `DependencyContainer` will lead to such code:
*/

protocol Server: class {
    weak var client: ServerClient? {get set}
}

protocol ServerClient: class {
    var server: Server? {get}
}

class ServerImp: Server {
    weak var client: ServerClient?
}

class ServerClientImp: ServerClient {
    var server: Server?
    
    init(server: Server) {
        self.server = server
    }
}

container.register(.ObjectGraph) {
    ServerClientImp(server: try! container.resolve()) as ServerClient
}

container.register(.ObjectGraph) { ServerImp() as Server }
    .resolveDependencies { container, server in
        server.client = try! container.resolve() as ServerClient
}

let client = try! container.resolve() as ServerClient
client.server

/*:
With auto-injection you will have the following code:
*/

class InjectedServerImp: Server {
    private var injectedClient = InjectedWeak<ServerClient>()
    var client: ServerClient? { get { return injectedClient.value } set { injectedClient.value = newValue }}
}

class InjectedClientImp: ServerClient {
    private var injectedServer = Injected<Server>()
    var server: Server? { get { return injectedServer.value} }
}

container.register(.ObjectGraph) { InjectedServerImp() as Server }
container.register(.ObjectGraph) { InjectedClientImp() as ServerClient }

let injectedClient = try! container.resolve() as ServerClient
injectedClient.server
injectedClient.server?.client === injectedClient //circular dependencies were resolved correctly

/*:
You can see that component registration looks much simpler now. But on the otherside it requires some boilerplate code in implementations, also tightly coupling them with Dip.

There is one more use case when auto-injection can be very helpfull - when you don't create instances by yourself but system creates them for you. It can be view controllers created by Storyboards. Let's say each view controller in your application requires logger, tracker, data layer service, router, etc. You can end up with code like this:
*/
container.register() { RouterImp() as Router }
container.register() { DataProviderImp() as DataProvider }

class ViewController: UIViewController {
    var logger: Logger?
    var tracker: Tracker?
    var dataProvider: DataProvider?
    var router: Router?

    //it's better not to access container directly in implementation but that's ok for illustration
    func injectDependencies(container: DependencyContainer) {
        logger = try! container.resolve() as Logger
        tracker = try! container.resolve() as Tracker
        dataProvider = try! container.resolve() as DataProvider
        router = try! container.resolve() as Router
    }
}

let viewController = ViewController()
viewController.injectDependencies(container)
viewController.router

/*:
With auto-injection you can replace that with something like this:
*/

class AutoInjectedViewController: UIViewController {
    
    var logger = Injected<Logger>()
    var tracker = Injected<Tracker>()
    var dataProvider = Injected<DataProvider>()
    var router = Injected<Router>()

    func injectDependencies(container: DependencyContainer) {
        container.resolveDependencies(self)
    }
}

let autoViewController = AutoInjectedViewController()
autoViewController.injectDependencies(container)
autoViewController.router.value

/*:
In such scenario you will need to use property injection anyway, so the overhead of adding additional properties for auto-injection is smaller. Also all the boilerplate code of unwrapping injected properties (if you need that) can be moved to extension, cleaning implementation a bit.

So as you can see there are certain advantages and disadvatages of using auto-injection. It makes your definitions simpler, especially if there are circular dependencies involved, and lets you get rid of giant constructors overloaded with arguments. But it requires additional properties and some boilerplate code in your implementations, makes your implementatios tightly coupled with Dip. It has also some limitations like that it requires factories for auto-injected types that accept no runtime arguments and have no associated tags to be registered in a container.

So you should decide for yourself whether you prefer to use auto-injection or "the standard" way. At the end they let you achieve the same result.
*/

//: [Next: Testing](@next)
