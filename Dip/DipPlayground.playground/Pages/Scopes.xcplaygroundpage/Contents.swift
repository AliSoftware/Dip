//: [Previous](@previous)

import Dip

/*:

### Scopes

Dip supports two different scopes of objects: _Prototype_ and _Singleton_. First will make container to resolve type as a new instance every time you call `resolve`. Singleton scope will make it to retain once resolved instance and reuse it during container lifetime.

Prototype scope is default. To register singleton use `register(tag:instance:)`
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

//: [Next](@next)
