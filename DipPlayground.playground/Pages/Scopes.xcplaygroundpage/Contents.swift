//: [Previous: Runtime Arguments](@previous)

import Dip

let container = DependencyContainer()

/*:

### Scopes

Dip supports three different scopes of objects: _Prototype_, _ObjectGraph_ and _Singleton_.

* The `.Prototype` scope will make the `DependencyContainer` resolve your type as __a new instance every time__ you call `resolve`.
* The `.ObjectGraph` scope is like `.Prototype` scope but it will make the `DependencyContainer` to reuse resolved instances during one call to `resolve` method. When this call returns all resolved insances will be discarded and next call to `resolve` will produce new instances. This scope should be used to resolve [circular dependencies](Circular%20dependencies).
* The `.Singleton` scope will make the `DependencyContainer` retain the instance once resolved the first time, and reuse it in the next calls to `resolve` during the container lifetime.

The `.Prototype` scope is the default. To set a scope you pass it as an argument to `register` method.
*/

container.register { ServiceImp1() as Service }
container.register(tag: "prototype", .Prototype) { ServiceImp1() as Service }
container.register(tag: "object graph", .ObjectGraph) { ServiceImp2() as Service }
container.register(tag: "shared instance", .Singleton) { ServiceImp3() as Service }

let service = container.resolve() as Service
let anotherService = container.resolve() as Service
service as! ServiceImp1 === anotherService as! ServiceImp1

let prototypeService = container.resolve(tag: "prototype") as Service
let anotherPrototypeService = container.resolve(tag: "prototype") as Service
prototypeService as! ServiceImp1 === anotherPrototypeService as! ServiceImp1

let graphService = container.resolve(tag: "object graph") as Service
let anotherGraphService = container.resolve(tag: "object graph") as Service
graphService as! ServiceImp2 === anotherGraphService as! ServiceImp2

let sharedService = container.resolve(tag: "shared instance") as Service
let sameSharedService = container.resolve(tag: "shared instance") as Service
sharedService as! ServiceImp3 === sameSharedService as! ServiceImp3

//: [Next: Circular Dependencies](@next)

