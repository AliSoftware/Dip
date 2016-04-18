//: [Previous: Creating a DependencyContainer](@previous)

import Dip

/*:

### Registering components

You register a definition in a container using the `register` method:
*/
let container = DependencyContainer()
container.register { ServiceImp1() as Service }

/*:
That code means that when you need a `Service`, you want to use instances of `ServiceImp1` class created with it's `init()` initializer.

You can also register factories that accept runtime arguments:
*/

container.register { service in ClientImp1(service: service) as Client }

/*:
Dip supports up to six runtime arguments, but you can use as many as you want. For more details see ["Runtime arguments"](Runtime%20arguments).

You can also use factory methods in definitions. This can be useful if you already have some factories but want to migrate to Dip.
*/

let factory = ServiceFactory()
// factory.someService is a method with signature `() -> Service`, Cmd-Click to see definition
container.register(factory: factory.someService)

/*:
Optionally you can associate definitions with Integer or String tags. This way you can register different implementations for the same protocol.  
You can use `DependencyContainer.Tag` enum, String or Integer literals, or instances of types that conform to `DependencyTagConvertible` protocol.
*/

container.register(tag: "tag") { ServiceImp1() as Service }
container.register(tag: 0) { ServiceImp1() as Service }

enum MyCustomTag: String, DependencyTagConvertible {
    case SomeTag
}

container.register(tag: MyCustomTag.SomeTag) { ServiceImp1() as Service }

/*:
We recommand you to use constants for the tags, to make the intent clear and avoid magic numbers and typos.

You can remove all registered definitions or register and remove them one by one:
*/

let serviceDefinition = container.register { ServiceImp1() as Service }
container
container.remove(serviceDefinition)

container.reset()

//: [Next: Resolving Components](@next)
