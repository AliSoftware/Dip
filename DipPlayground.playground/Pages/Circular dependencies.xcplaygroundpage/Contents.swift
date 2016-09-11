//: [Previous: Scopes](@previous)

import Dip
import Foundation

let container = DependencyContainer()

/*:
### Circular Dependencies

Very often we encounter situations when we have circular dependencies between components. The most obvious example is delegation pattern. Dip can resolve such dependencies easily.

Let's say you have some network client and it's delegate defined like this:
*/

protocol NetworkClientDelegate: class {
    var networkClient: NetworkClient { get }
}

protocol NetworkClient: class {
    weak var delegate: NetworkClientDelegate? { get set }
}

class NetworkClientImp: NetworkClient {
    weak var delegate: NetworkClientDelegate?
    init() {}
}

class Interactor: NSObject, NetworkClientDelegate {
    let networkClient: NetworkClient
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
}

/*:
Note that:

 - one of this classes uses _property injection_ (`NetworkClientImp`) — you'll give the `delegate` value via its property directly, _after_ initialization
 - and another uses _constructor injection_ (`Interactor`) — you'll need to give the `networkclient` value via the constructor, _during_ initialization.

It's very important that _at least one_ of them uses property injection, because if you try to use constructor injection for both of them then you will enter infinite loop when you will call `resolve`.

Now you can register those classes in container:
*/

container.register {
    Interactor(networkClient: try container.resolve()) as NetworkClientDelegate
}

container.register { NetworkClientImp() as NetworkClient }
    .resolvingProperties { (container, client) -> () in
        client.delegate = try container.resolve() as NetworkClientDelegate
}

/*:
Here you can spot the difference in the way we register classes.

 - `Interactor` class uses constructor injection, so to register it we use the block factory where we call `resolve` to obtain instance of `NetworkClient` and pass it to constructor.
 - `NetworkClientImp` uses property injection for it's delegate property. Again we use block factory to create instance, but to inject the delegate property we use the special `resolveDependencies` method. Block passed to this method will be called right _after_ the block factory. So you can use this block to perform additional setup or, like in this example, to resolve circular dependencies.

This way `DependencyContainer` breaks infinite recursion that would happen if we used constructor injection for both of our components.

*Note*: You can use container reference inside instance factory without using capture list, there will be [no retain cycle](https://github.com/AliSoftware/Dip/issues/23)


Now when you resolve `NetworkClientDelegate` you will get an instance of `Interactor` that will have client with delegate referencing the same `Interactor` instance:
*/

let interactor = try! container.resolve() as NetworkClientDelegate
interactor.networkClient.delegate === interactor // true: they are the same instances

/*:
**Warning**: Note that one of the properties (`delegate`) is defined as _weak_. That's crucial to avoid retain cycle. But now if you try to resolve `NetworkClient` first it's delegate will be released before `resolve` returns, bcause no one holds a reference to it except the container.
*/

let networkClient = try! container.resolve() as NetworkClient
networkClient.delegate // delegate was alread released =(

/*:
Note also that we used `.shared` scope to register implementations. This is also very important to preserve consistency of objects relationships.

If we would have used `.unique` scope for both components then container would not reuse instances and we would have an infinite loop:

 - Each attempt to resolve `NetworkClientDelegate` will create new instance of `Interactor`.
 - It will resolve `NetworkClient` which will create new instance of `NetworkClientImp`.
 - It will try to resolve it's delegate property and that will create new instance of `Interactor`
 - … And so on and so on.

If we would have used `.unique` for one of the components it will lead to the same infinite loop or one of the relationships will be invalid:
*/

container.reset()

container.register(.unique) {
    Interactor(networkClient: try container.resolve()) as NetworkClientDelegate
}

container.register { NetworkClientImp() as NetworkClient }
    .resolvingProperties { (container, client) -> () in
        client.delegate = try container.resolve() as NetworkClientDelegate
}

let invalidInteractor = try! container.resolve() as NetworkClientDelegate
invalidInteractor.networkClient.delegate // that is not valid

//: [Next: Shared Instances](@next)
