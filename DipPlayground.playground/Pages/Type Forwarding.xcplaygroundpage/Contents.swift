//: [Previous: Auto-injection](@previous)

import Foundation
import Dip

let container = DependencyContainer()

/*:
### Type Forwarding
 
Very often we end up with single class that implements several protocols. This is normal even in [VIPER architecture](https://github.com/mutualmobile/VIPER-SWIFT/blob/master/VIPER-SWIFT/Classes/Modules/List/User%20Interface/Presenter/ListPresenter.swift#L12) that constantly strives for Single Responsibility Principle.
 
 Let's look at example of VIPER architecture:
 */

extension ListPresenter: ListInteractorOutput, ListModuleInterface, AddModuleDelegate {}
extension ListInteractor: ListInteractorInput {}
extension AddPresenter: AddModuleInterface {}

/*:
 In VIPER we need to create several objects (presenters, wireframes, interactors) which should be accessed thorugh different interfaces. We need to wire them all together so that we have the same instances in place for different types.
 
 - `ListInteractor` referenced by `ListPresenter` in its `listInteractor` property (via `ListInteractorInput` protocol) should hold a backward reference to the same presenter in its `output` property
 - `ListWireframe` referenced by `ListPresenter` should also hold a backward reference to the same presenter in its `listPresenter` property
 - `AddWireframe` should hold a reference to `AddPresenter` that should hold reference to the same `ListPresenter` in its `addModuleDelegate` property (via `AddModuleDelegate` protocol).
 
 We can achieve this result by explicitly rosolving concrete types:
 */

container.register { ListWireframe(addWireFrame: $0, listPresenter: $1) }
container.register { AddWireframe(addPresenter: $0) }

var listInteractorDefinition = container.register { ListInteractor() }
    .resolvingProperties { container, interactor in
        interactor.output = try container.resolve() as ListPresenter
}

var listPresenterDefinition = container.register { ListPresenter() }
    .resolvingProperties { container, presenter in
        presenter.listInteractor = try container.resolve() as ListInteractor
        presenter.listWireframe = try container.resolve()
}

var addPresenterDefinition = container.register { AddPresenter() }
    .resolvingProperties { container, presenter in
        presenter.addModuleDelegate = try container.resolve() as ListPresenter
}

var addPresenter = try! container.resolve() as AddPresenter
var listPresenter = addPresenter.addModuleDelegate as! ListPresenter
var listInteractor = listPresenter.listInteractor as! ListInteractor
listInteractor.output === listPresenter
var listWireframe = listPresenter.listWireframe
listWireframe?.listPresenter === listPresenter

/*:
 Alternatively we can use type-forwarding. With type-forwarding we register definition for one (source) type and also for another (forwarded) type. When container will try to resolve forwarded type it will use the same definition as for source type, and (if registered in `Shared` scope or as a singleton) will reuse the same instance. With that you don't need to resolve concrete types in definitions:
 */

listInteractorDefinition = container.register { ListInteractor() }
    .resolvingProperties { container, interactor in
        interactor.output = try container.resolve()
}

listPresenterDefinition = container.register { ListPresenter() }
    .resolvingProperties { container, presenter in
        presenter.listInteractor = try container.resolve()
        presenter.listWireframe = try container.resolve()
}

addPresenterDefinition = container.register { AddPresenter() }
    .resolvingProperties { container, presenter in
        presenter.addModuleDelegate = try container.resolve()
}

/*:
 And now we register definitions for type-forwarding:
 */
listInteractorDefinition
    .implements(ListInteractorInput.self)
listPresenterDefinition
    .implements(ListInteractorOutput.self)
    .implements(ListModuleInterface.self)
    .implements(AddModuleDelegate.self)

addPresenter = try! container.resolve() as AddPresenter
listPresenter = addPresenter.addModuleDelegate as! ListPresenter
listInteractor = listPresenter.listInteractor as! ListInteractor
listInteractor.output === listPresenter
listWireframe = listPresenter.listWireframe
listWireframe?.listPresenter === listPresenter

/*:
 Type forwarding will work the same way whenever your resolve dependencies with property injection using `resolveDependencies` block, or with auto-injected properties, or with constructor injection and auto-wiring.
 
 Registering definition for type forwarding will effectively register another definition in the container, linked with original one. So the same overriding rool will be applied for such registrations - last wins. If you need to register different definitions for the same type you should register them with different tags.
 
 You can also provide `resolveDependencies` block for forwarded definition. First container will call `resolveDependencies` block of the source definition, and then of forwarded definition:
 */
listInteractorDefinition
    .resolvingProperties { container, interactor in
        print("resolved ListInteractor")
}
let _ = container.register(listInteractorDefinition, type: ListInteractorInput.self)
    .resolvingProperties { container, interactor in
        print("resolved ListInteractorInput")
}
addPresenter = try! container.resolve() as AddPresenter

//: [Next: Containers Collaboration](@next)
