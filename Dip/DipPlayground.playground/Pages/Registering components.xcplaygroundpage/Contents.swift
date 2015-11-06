//: [Previous](@previous)

import Dip

/*:

### Registering components

You register definition in container using `register` method:
*/
let container = DependencyContainer()
container.register { ServiceImp1() as Service }

/*:
That code means that as `Service` you want to use instance of `ServiceImp1` class created with it's `init()` initializer.

You can register factories that accept runtime arguments:
*/

container.register { service in ClientImp1(service: service) as Client }

/*:
Dip supports up to six runtime arguments, but you can use as many as you want. For more details see ["Runtime arguments"](Runtime%20arguments).

Also you can use factory methods in definitions. That can be usefull if you already have some factories but want to migrate to Dip.
*/

let factory = ServiceFactory()
container.register(factory: factory.someService)

/*:
Optionally you can associate definitions with Integer or String tags. This way you can register different implementations of the same protocol. You can use String or Integer literals, or DependencyContainer.Tag enum.
*/

container.register(tag: "tag") { ServiceImp1() as Service }
container.register(tag: DependencyContainer.Tag.Int(0)) { ServiceImp1() as Service }

//: [Next](@next)
