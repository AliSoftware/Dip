//: [Previous](@previous)

import Dip
let container = DependencyContainer { container in
    container.register { ServiceImp1() as Service }
}

/*:

### Resolving components

You resolve previously registered definition using `resolve` method:
*/

var service = container.resolve() as Service

/*:
That code says that you want container to give you an instance that was registered as implementation of `Service` protocol.

It's important to specify the same type that you used for registration. You can use either `as` syntax, or specify type of you variable when you define it:
*/

let otherService: Service = container.resolve()

/*:
Both ways will let container to detect type that you want to resolve. 'as' syntax is preferable cuase it reads more natural in Swift.

If you used tag to register component you can use the same tag to resolve it. If there is no definition with such tag container will try to find definition for the same type with `nil` tag and resolve it.
*/

container.register(tag: "production") { ServiceImp1() as Service }
container.register(tag: "test") { ServiceImp2() as Service }

let productionService = container.resolve(tag: "production") as Service
let testService = container.resolve(tag: "test") as Service
let defaultService = container.resolve() as Service

/*:
You can use runtime arguments to resolve components. Dip supprots up to six arguments. For more details see ["Runtime arguments"](Runtime%20arguments).
*/
container.register { service in ClientImp1(service: service) as Client }
let client = container.resolve(service) as Client

//: [Next](@next)
