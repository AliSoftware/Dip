//: [Previous: Runtime Arguments](@previous)

import Dip

/*:

### Scopes

Dip supports two different scopes of objects: _Prototype_ and _Singleton_.

* The `.Prototype` scope will make the `DependencyContainer` resolve your type as __a new instance every time__ you call `resolve`.
* The `.Singleton` scope will make the `DependencyContainer` retain the instance once resolved the first time, and reuse it in the next calls during the container lifetime.

The `.Prototype` scope is the default. To register a singleton, use `register(tag:instance:)`
*/

let container = DependencyContainer { container in
    container.register(tag:"sharedService", instance: ServiceImp1() as Service)
    container.register { ServiceImp1() as Service }
}

let sharedService = container.resolve(tag: "sharedService") as Service
let sameSharedService = container.resolve(tag: "sharedService") as Service
sharedService as! ServiceImp1 === sameSharedService as! ServiceImp1

let service = container.resolve() as Service
let anotherService = container.resolve() as Service
service as! ServiceImp1 === anotherService as! ServiceImp1

