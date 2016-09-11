//: [Previous: Resolving Components](@previous)

import Dip

let container = DependencyContainer()

/*:

### Runtime arguments

Dip lets you use runtime arguments to register and resolve your components.
Note that __types__, __number__ and __order__ of arguments matters and you can register different factories with different set of runtime arguments for the same protocol. To resolve using one of this factory you will need to pass runtime arguments of the same types, number and in the same order to `resolve` as you used in `register` method.
*/

container.register { (url: NSURL, port: Int) in ServiceImp4(name: "1", baseURL: url, port: port) as Service }
container.register { (port: Int, url: NSURL) in ServiceImp4(name: "2", baseURL: url, port: port) as Service }
container.register { (port: Int, url: NSURL?) in ServiceImp4(name: "3", baseURL: url!, port: port) as Service }

let url: NSURL = NSURL(string: "http://example.com")!
let service1 = try! container.resolve(arguments: url, 80) as Service
let service2 = try! container.resolve(arguments: 80, url) as Service
let service3 = try! container.resolve(arguments: 80, NSURL(string: "http://example.com")) as Service

(service1 as! ServiceImp4).name
(service2 as! ServiceImp4).name
(service3 as! ServiceImp4).name

/*:
Note that all of the services were resolved using different factories.

_Dip_ supports up to six runtime arguments. If that is not enougth you can extend `DependencyContainer` to accept more arguments. For example, here is how you can extend it to serve seven arguments.
*/

extension DependencyContainer {
    
    @discardableResult
    public func register<T, A, B, C, D, E, F, G>(_ scope: ComponentScope = .shared, type: T.Type = T.self, tag: DependencyTagConvertible? = nil, factory: @escaping (A, B, C, D, E, F, G) throws -> T) -> Definition<T, (A, B, C, D, E, F, G)> {
        return register(scope: scope, type: type, tag: tag, factory: factory, numberOfArguments: 7) { container, tag in
            try factory(container.resolve(tag: tag), container.resolve(tag: tag), container.resolve(tag: tag), container.resolve(tag: tag), container.resolve(tag: tag), container.resolve(tag: tag), container.resolve(tag: tag))
        }
    }
    
    public func resolve<T, A, B, C, D, E, F, G>(tag: DependencyTagConvertible? = nil, _ arg1: A, _ arg2: B, _ arg3: C, _ arg4: D, _ arg5: E, _ arg6: F, _ arg7: G) throws -> T {
        return try resolve(tag: tag) { factory in try factory(arg1, arg2, arg3, arg4, arg5, arg6, arg7) }
    }
}

/*:
However, if you find yourself thinking about adding more runtime arguments, stop and think about your design instead. Having too many dependencies could be a sign of some problem in your architecture, so we strongly suggest that you refrain from doing so; six runtime arguments is already a lot.
*/

//: [Next: Scopes](@next)
