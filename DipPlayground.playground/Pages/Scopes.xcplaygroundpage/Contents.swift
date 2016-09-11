//: [Previous: Runtime Arguments](@previous)

import Dip

let container = DependencyContainer()

/*:

### Scopes

Dip supports three different scopes of objects: _Unique_, _Shared_ and _Singleton_.

* The `Unique` scope will make the `DependencyContainer` resolve your type as __a new instance every time__ you call `resolve`. This is the default scope.
* The `Shared` scope is like `Unique` scope, but it will make the `DependencyContainer` to reuse resolved instances during one (recursive) call to `resolve` method. When this call returns, all resolved instances will be discarded and next call to `resolve` will produce new instances. This scope should be used to resolve [circular dependencies](Circular%20dependencies).
* The `Singleton` scope will make the `DependencyContainer` retain the instance once resolved the first time, and reuse it in the next calls to `resolve` during the container lifetime.
* The `EagerSingleton` scope is the same as `Singleton` scope but instances with this cope will be created when you call `bootstrap()` method on the container.
* The `WeakSingleton` scope is the same as `Singleton` scope but instances are stored in container as weak references. This scope can be usefull when you need to recreate object graph without reseting container.

The `Unique` scope is the default. To set a scope you pass it as an argument to `register` method.
*/

container.register { ServiceImp1() as Service }
container.register(.unique, tag: "prototype") { ServiceImp1() as Service }
container.register(.shared, tag: "object graph") { ServiceImp2() as Service }
container.register(.singleton, tag: "shared instance") { ServiceImp3() as Service }

let service = try! container.resolve() as Service
let anotherService = try! container.resolve() as Service
// They are different instances as the scope defaults to .unique
service as! ServiceImp1 === anotherService as! ServiceImp1 // false

let prototypeService = try! container.resolve(tag: "prototype") as Service
let anotherUniqueService = try! container.resolve(tag: "prototype") as Service
// They are different instances:
prototypeService === anotherUniqueService // false

let graphService = try! container.resolve(tag: "object graph") as Service
let anotherGraphService = try! container.resolve(tag: "object graph") as Service
// still different instances — the Shared scope only keep instances during one (recursive) resolution call,
// so the two calls on the two lines above are different calls and use different instances
graphService === anotherGraphService // false

let sharedService = try! container.resolve(tag: "shared instance") as Service
let sameSharedService = try! container.resolve(tag: "shared instance") as Service
// same instances, the singleton scope keep and reuse instances during the lifetime of the container
sharedService as! ServiceImp3 === sameSharedService as! ServiceImp3

/*:
 ### Bootstrapping
 
 You can use `bootstrap()` method to fix your container setup and initialise components registered with `EagerSingleton` scope.
 After bootstrapping if you try to add or remove any definition it will cause runtime exception. Call `boostrap` when you registered all the components, for example at the end of initialization block if you use `init(configBlock:)`.
 */

var resolvedEagerSingleton = false
let definition = container.register(.eagerSingleton, tag: "eager shared instance") { ServiceImp1() as Service }
    .resolvingProperties { _ in resolvedEagerSingleton = true }

try! container.bootstrap()
resolvedEagerSingleton

let eagerSharedService = try! container.resolve(tag: "eager shared instance") as Service

container.remove(definition)

//: [Next: Circular Dependencies](@next)

