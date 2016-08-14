//: [Previous: Registering Components](@previous)

import Dip
let container = DependencyContainer()
container.register { ServiceImp1() as Service }

/*:

### Resolving components

You resolve previously registered definition using `resolve` method:
*/

var service = try! container.resolve() as Service

/*:
That code says that you want your `container` to give you an instance that was registered as implementation of `Service` protocol.

It's important to specify the same type that you used for registration. You can use either `as` syntax, or specify type of you variable when you define it:
*/

let otherService: Service = try! container.resolve()

/*:
Both ways will let the `container` detect the type that you want to resolve as. We prefer the `as` syntax because it reads more naturally in Swift.

If you used a tag to register your component, you can use the same tag to resolve it. If there is no definition with such tag, the `container` will try to find a definition for the same type with no tag (`nil` tag), and resolve it instead, allowing you to provide default components in such cases.
*/

container.register(tag: "production") { ServiceImp1() as Service }
container.register(tag: "test") { ServiceImp2() as Service }

// Will give you a ServiceImp1 instance
let productionService = try! container.resolve(tag: "production") as Service
// Will give you a ServiceImp2 instance
let testService = try! container.resolve(tag: "test") as Service
// Will give you a ServiceImp1 because one was registered without a tag on line 4
let defaultService = try! container.resolve() as Service

/*:
You can use runtime arguments to resolve components. Dip supports up to six arguments. For more details see ["Runtime arguments"](Runtime%20arguments).
*/
container.register { service in ClientImp1(service: service) as Client }
let client = try! container.resolve(arguments: service) as Client

//: [Next: Runtime Arguments](@next)
