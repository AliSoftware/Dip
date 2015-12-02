//: [Previous: Runtime Arguments](@previous)

import Dip

let container = DependencyContainer()

/*:

### Scopes

Dip supports three different scopes of objects: _Prototype_, _ObjectGraph_ and _Singleton_.

* The `.Prototype` scope will make the `DependencyContainer` resolve your type as __a new instance every time__ you call `resolve`. This is the default scope.
* The `.ObjectGraph` scope is like `.Prototype` scope, but it will make the `DependencyContainer` to reuse resolved instances during one (recursive) call to `resolve` method. When this call returns, all resolved instances will be discarded and next call to `resolve` will produce new instances. This scope should be used to resolve [circular dependencies](Circular%20dependencies).
* The `.Singleton` scope will make the `DependencyContainer` retain the instance once resolved the first time, and reuse it in the next calls to `resolve` during the container lifetime.

The `.Prototype` scope is the default. To set a scope you pass it as an argument to `register` method.
*/

container.register { ServiceImp1() as Service }
container.register(tag: "prototype", .Prototype) { ServiceImp1() as Service }
container.register(tag: "object graph", .ObjectGraph) { ServiceImp2() as Service }
container.register(tag: "shared instance", .Singleton) { ServiceImp3() as Service }

let service = try! container.resolve() as Service
let anotherService = try! container.resolve() as Service
// They are different instances as the scope defaults to .Prototype
service as! ServiceImp1 === anotherService as! ServiceImp1 // false

let prototypeService = try! container.resolve(tag: "prototype") as Service
let anotherPrototypeService = try! container.resolve(tag: "prototype") as Service
// They are different instances:
prototypeService as! ServiceImp1 === anotherPrototypeService as! ServiceImp1 // false

let graphService = try! container.resolve(tag: "object graph") as Service
let anotherGraphService = try! container.resolve(tag: "object graph") as Service
// still different instances — the ObjectGraph scope only keep instances during one (recursive) resolution call,
// so the two calls on the two lines above are different calls and use different instances
graphService as! ServiceImp2 === anotherGraphService as! ServiceImp2 // false

let sharedService = try! container.resolve(tag: "shared instance") as Service
let sameSharedService = try! container.resolve(tag: "shared instance") as Service
// same instances, the singleton scope keep and reuse instances during the lifetime of the container
sharedService as! ServiceImp3 === sameSharedService as! ServiceImp3

//: [Next: Circular Dependencies](@next)

