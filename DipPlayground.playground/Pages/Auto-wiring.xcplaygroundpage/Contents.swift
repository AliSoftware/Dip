//: [Previous: Shared Instances](@previous)

import Dip
import UIKit

/*:

### Auto-wiring

Among three main DI patterns - _constructor_, _property_ and _method_ injection - constructor injection should be your choise by default. Dip makes using this pattern very simple.

Let's say you have some VIPER module with following components:
*/
protocol Service {}
protocol Interactor {
    var service: Service { get }
}
protocol Router {}
protocol ViewOutput {}
protocol Presenter {
    var router: Router { get }
    var interactor: Interactor { get }
    var view: ViewOutput { get }
}

class RouterImp: Router {}
class View: UIView, ViewOutput {}
class ServiceImp: Service {}

/*:
VIPER module by its nature consists of a lot of components, wired up using protocols. Using constructor injection you can end up with following constructors for presenter and interactor:
*/

class InteractorImp: Interactor {
    var service: Service
    
    init(service: Service) {
        self.service = service
    }
}

class PresenterImp: Presenter {
    let router: Router
    let interactor: Interactor
    let view: ViewOutput
    
    init(view: ViewOutput, interactor: Interactor, router: Router) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }
}

/*:
If you register these components in a container you will end up with rather boilerplate code:
*/

let container = DependencyContainer()
container.register { ServiceImp() as Service }
container.register { RouterImp() as Router }
container.register { View() as ViewOutput }

container.register { try InteractorImp(service: container.resolve()) as Interactor }
container.register {
    try PresenterImp(
        view: container.resolve(),
        interactor: container.resolve(),
        router: container.resolve()) as Presenter
}


var presenter = try! container.resolve() as Presenter
presenter.interactor.service

/*:
While definition for `Interactor` looks fine, `Presenter`'s definition is overloaded with the same `resolve` calls to container.

The other option you have is to register factory with runtime arguments:
*/

container.register { InteractorImp(service: $0) as Interactor }
container.register { PresenterImp(view: $0, interactor: $1, router: $2) as Presenter }

/*: 
But then to resolve presenter or interactor you will first need to resolve their dependencies and pass them as arguments to `resolve` method:
*/

let service = try! container.resolve() as Service
let interactor = try! container.resolve(arguments: service) as Interactor
let view = try! container.resolve() as ViewOutput
let router = try! container.resolve() as Router
presenter = try! container.resolve(arguments: view, interactor, router) as Presenter
presenter.interactor.service

/*:
Again to much of boilerplate code. Also it's easy to make a mistake in the order of arguments.

Auto-wiring solves this problem by combining these two approaches - you register factories with runtime arguments, but resolve components with just a call to `resolve()`. Container will resolve all consturctor arguments for you.
*/

container.register { InteractorImp(service: $0) as Interactor }
container.register { PresenterImp(view: $0, interactor: $1, router: $2) as Presenter }

presenter = try! container.resolve() as Presenter
presenter.interactor.service

/*:
You don't need to call `resolve` in a factory and care about order of arguments any more.

The only requirement is that all constructor arguments should be registered in the container and there should be no several factories with the same _number_ of arguments registered for the same components. 

In very rare cases when you have several factories for the same component with different set of runtime arguments, when you try to resolve it container will try to use factory registered for the same type and tag (if provided, otherwise registered without tag) and with the maximum number of runtime arguments. If it finds two factories registered for the same type and tag and with the same number but different types of arguments it will throw an error.

You can use auto-wiring with tags. The tag that you pass to `resolve` method will be used to resolve each of the constructor arguments.
*/

//: [Next: Auto-injection](@next)
