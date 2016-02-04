//: [Previous: Shared Instances](@previous)

import UIKit
import Dip

let container = DependencyContainer()
/*:

### Auto-Injection

If you follow Single Responsibility Principle chances are very high that you will end up with more than two collaborating components in your system. Let's say you have a component that depends on few others. Using _Dip_ you can register all of the dependencies in a container as well as that component itself and register a factory that will create that component and feed it with the dependencies resolving them with a container:
*/

protocol Service: class {
    var logger: Logger? { get }
    var tracker: Tracker? { get }
}

class ServiceImp: Service {
    var logger: Logger?
    var tracker: Tracker?
}

container.register() { TrackerImp() as Tracker }
container.register() { LoggerImp() as Logger }

container.register() { ServiceImp() as Service }
    .resolveDependencies { container, service in
        (service as! ServiceImp).logger = try container.resolve() as Logger
        (service as! ServiceImp).tracker = try container.resolve() as Tracker
}

let service = try! container.resolve() as Service
service.logger
service.tracker

/*:
Not bad so far. Though that `resolveDependencies` block looks heavy. It would be cool if we can get rid of it. Alternatively you can use _constructor injection_ here, which is actually more prefereable by default but not always possible (see [circular dependencies](Circular%20dependencies)).
Now let's say that you have a bunch of components in your app that require `Logger` or `Tracker` too. You will need to resolve them in a factory for each component again and again. That can be a lot of boilerplate code, simple but still duplicated.

That is one of the scenarios when auto-injection can be useful. It works with property injection and with it the previous code will transform to this:
*/

class AutoInjectedServiceImp: Service {
    private var injectedLogger = Injected<Logger>()
    var logger: Logger? { return injectedLogger.value }
    
    private var injectedTracker = Injected<Tracker>()
    var tracker: Tracker? { return injectedTracker.value }
}

container.register() { AutoInjectedServiceImp() as Service }

let autoInjectedService = try! container.resolve() as Service
autoInjectedService.logger
autoInjectedService.tracker

/*:
As you can see we added two private properties to our implementation of `Service` - `injectedLogger` and `injectedTracker`. Their types are `Injeceted<Logger>` and `Injected<Tracker>` respectively. Note that we've not just defined them as properties of those types, but defined them with some initial value. `Injected<T>` is a simple _wrapper class_ that wraps value of generic type and provides read-write access to it with `value` property. This property is defined as optional, so that when we create instance of `Injected<T>` it will have `nil` in its value. There is also another wrapper - `InjectedWeak<T>` - which in contrast to `Injected<T>` holds a week reference to its wrapped object, thus requiring it to be a _reference type_ (or `AnyObject`), when `Injected<T>` can also wrap value types (or `Any`).

What is happening under the hood is that after concrete instance of resolved type is created (`Service` in that case), container will iterate through its properties using `Mirror`. For each of the properties wrapped with `Injected<T>` or `InjectedWeak<T>` it will search a definition that can be used to create an instance of wrapped type and use it to create and inject a concrete instance in a `value` property of a wrapper. The fact that wrappers are _classes_ or _reference types_ makes it possible at runtime to inject dependency in instance of resolved type.

You can provide closure that will be called when the dependency will be injected in the property. It is similar to `didSet` property observer.

Auto-injected properties can be marked with tag. Then container will search for definition tagged by the same tag to resolve this property.

Auto-injected properties are required by default. That means that if container fails to resolve any of auto-injected properties of the instance (or any of its dependencies) it will fail resolution of the object graph in whole.
*/

class ServerWithRequiredClient {
    var client = Injected<Client>()
}

container.register { ServerWithRequiredClient() }

do {
    let serverWithClient = try container.resolve() as ServerWithRequiredClient
}
catch {
    print(error)
}

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

container.register(.ObjectGraph) {
    ServerClientImp(server: try container.resolve()) as ServerClient
}

container.register(.ObjectGraph) { ServerImp() as Server }
    .resolveDependencies { (container: DependencyContainer, server: Server) in
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

container.register(.ObjectGraph) { InjectedServerImp() as Server }
container.register(.ObjectGraph) { InjectedClientImp() as ServerClient }

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
    .resolveDependencies { container, controller in
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

> **Note**: For such cases concider using [DipUI](https://github.com/AliSoftware/Dip-UI). It is a small extension for Dip that allows you to do exactly what we need in this example - inject dependencies in instances created by storyboards. It does not require to use auto-injection feature.

So as you can see there are certain advantages and disadvatages of using auto-injection. It makes your definitions simpler, especially if there are circular dependencies involved or the number of dependencies is high. But it requires additional properties and some boilerplate code in your implementations, makes your implementatios tightly coupled with Dip. It has also some limitations like that it requires factories for auto-injected types that accept no runtime arguments to be registered in a container.

So you should decide for yourself whether you prefer to use auto-injection or "the standard" way. At the end they let you achieve the same result.
*/

//: [Next: Testing](@next)
