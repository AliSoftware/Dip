//: [Previous: Auto-wiring](@previous)

import UIKit
import Dip

let container = DependencyContainer()
/*:

### Auto-Injection

On the previous page you saw how auto-wiring helps us to get rid of boilerplate code when registering and resolving components with consturctor injection. Auto-injection solves the same problem for property injection.

Let's say you have following related components:
*/

protocol Service: class {
    var logger: Logger? { get }
    var tracker: Tracker? { get }
}

class ServiceImp: Service {
    var logger: Logger?
    var tracker: Tracker?
}

/*:
When you register them in a container you will end up with something like this:
*/

container.register() { TrackerImp() as Tracker }
container.register() { LoggerImp() as Logger }

container.register() { ServiceImp() as Service }
    .resolvingProperties { container, service in
        let service = service as! ServiceImp
        service.logger = try container.resolve() as Logger
        service.tracker = try container.resolve() as Tracker
}

let service = try! container.resolve() as Service
service.logger
service.tracker

/*:
Notice that the same boilerplate code that we saw in constructor injection now moved to `resolveDepedencies` block.
With auto-injection your code transforms to this:
*/

class AutoInjectedServiceImp: Service {
    private let injectedLogger = Injected<Logger>()
    var logger: Logger? { return injectedLogger.value }
    
    private let injectedTracker = Injected<Tracker>()
    var tracker: Tracker? { return injectedTracker.value }
}

container.register() { AutoInjectedServiceImp() as Service }

let autoInjectedService = try! container.resolve() as Service
autoInjectedService.logger
autoInjectedService.tracker

/*:
As you can see we added two private properties to our implementation of `Service` - `injectedLogger` and `injectedTracker`. Their types are `Injeceted<Logger>` and `Injected<Tracker>` respectively. Note that we've not just defined them as properties of those types, but defined them with some initial value. `Injected<T>` is a simple _wrapper class_ that wraps value of generic type and provides read-write access to it with `value` property. This property is defined as optional, so that when we create instance of `Injected<T>` it will have `nil` in its value. There is also another wrapper - `InjectedWeak<T>` - which in contrast to `Injected<T>` holds a week reference to its wrapped object, thus requiring it to be a _reference type_ (or `AnyObject`), when `Injected<T>` can also wrap value types (or `Any`).

What is happening under the hood is that after concrete instance of resolved type is created (`Service` in that case), container will iterate through its properties using `Mirror`. For each of the properties wrapped with `Injected<T>` or `InjectedWeak<T>` it will search a definition that can be used to create an instance of wrapped type and use it to create and inject a concrete instance in a `value` property of a wrapper. The fact that wrappers are _classes_ or _reference types_ makes it possible at runtime to inject dependency in instance of resolved type.

The requirement for auto-injection is that types injected types should be registered in a container and should use factories with no runtime arguments.

Auto-injected properties can be marked with tag. Then container will search for definition tagged by the same tag to resolve this property.

You can provide closure that will be called when the dependency will be injected in the property. It is similar to `didSet` property observer.

Auto-injected properties are required by default. That means that if container fails to resolve any of auto-injected properties of the instance (or any of its dependencies) it will fail resolution of the object graph in whole.
*/

class ServerWithRequiredClient {
    var client = Injected<Client>()
}

container.register { ServerWithRequiredClient() }

do {
    let serverWithClient = try container.resolve() as ServerWithRequiredClient
}
catch {}

/*:
You can make auto-injected property optional by passing `false` to `required` parameter of `Injected<T>`/`InjectedWeak<T>` constructor. For such properties container will ignore any errors when it resolves this property (or any of its dependencies).
*/

class ServerWithOptionalClient {
    var optionalClient = Injected<Client>(required: false)
}

container.register { ServerWithOptionalClient() }
let serverWithNoClient = try! container.resolve() as ServerWithOptionalClient
serverWithNoClient.optionalClient.value

/*:
Another example of using auto-injection is circular dependencies. Let's say you have a `Server` and a `ServerClient` both referencing each other.
*/

protocol Server: class {
    weak var client: ServerClient? { get }
}

protocol ServerClient: class {
    var server: Server? { get }
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

/*:
The standard way to register such components in `DependencyContainer` will lead to such code:
*/

container.register {
    ServerClientImp(server: try container.resolve()) as ServerClient
}

container.register { ServerImp() as Server }
    .resolvingProperties { (container: DependencyContainer, server: Server) in
        (server as! ServerImp).client = try container.resolve() as ServerClient
}

let client = try! container.resolve() as ServerClient
client.server

/*:
With auto-injection you will have the following code:
*/

class InjectedServerImp: Server {
    private var injectedClient = InjectedWeak<ServerClient>()
    var client: ServerClient? { return injectedClient.value }
}

class InjectedClientImp: ServerClient {
    private var injectedServer = Injected<Server>()
    var server: Server? { get { return injectedServer.value } }
}

container.register { InjectedServerImp() as Server }
container.register { InjectedClientImp() as ServerClient }

let injectedClient = try! container.resolve() as ServerClient
injectedClient.server
injectedClient.server?.client === injectedClient //circular dependencies were resolved correctly

/*:
You can see that component registration looks much simpler now. But on the other side it requires some boilerplate code in implementations, and also tightly coupls your code with Dip.

Here is an example with higher number of dependencies.
*/
container.register() { RouterImp() as Router }
container.register() { DataProviderImp() as DataProvider }

class ViewController: UIViewController {
    var logger: Logger?
    var tracker: Tracker?
    var dataProvider: DataProvider?
    var router: Router?
}

container.register { ViewController() }
    .resolvingProperties { container, controller in
        controller.logger = try container.resolve() as Logger
        controller.tracker = try container.resolve() as Tracker
        controller.dataProvider = try container.resolve() as DataProvider
        controller.router = try container.resolve() as Router
}

let viewController = try! container.resolve() as ViewController
viewController.router

/*:
With auto-injection you can replace that with something like this:
*/

class AutoInjectedViewController: UIViewController {
    let logger = Injected<Logger>()
    let tracker = Injected<Tracker>()
    let dataProvider = Injected<DataProvider>()
    let router = Injected<Router>()
}

container.register { AutoInjectedViewController() }

let autoViewController = try! container.resolve() as AutoInjectedViewController
autoViewController.router.value

/*:
In such scenario when view controller is created by storyboard you will need to use property injection anyway, so the overhead of adding additional properties for auto-injection is smaller. Also all the boilerplate code of unwrapping injected properties (if you need that) can be moved to extension, cleaning implementation a bit.

> **Note**: For such cases concider using [DipUI](https://github.com/AliSoftware/Dip-UI). It is a small extension for Dip that allows you to do exactly what we need in this example - inject dependencies in instances created by storyboards. It does not require to use auto-injection feature but plays nice with it.

So as you can see there are certain advantages and disadvatages of using auto-injection. It makes your definitions simpler, especially if there are circular dependencies involved or the number of dependencies is high, removing boilerplate calls to `resolve` method in `resolveDependencies` block of your definitions. But it requires additional properties and some boilerplate code in your implementations, makes your implementatios tightly coupled with Dip. You can avoid tight coupoling by using your own boxing classes instead of `Injected<T>` and `InjectedWeak<T>` (see `AutoInjectedPropertyBox`).
*/

//: [Next: Type Forwarding](@next)
