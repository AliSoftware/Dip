//: [Previous: Type Forwarding](@previous)

import Dip

/*:
 ### Containers collaboration

 Sometimes it makes sence to break your configuration in separate modules. For that you can use containers collaboration. You can link containers with each other and when you try to resolve a type using container where it was not registered, this container will forward request to its collaborating container. This way you can share core configurations or break them in separate modules, for example matching user stories, and still be able to link components from different modules.
 */

protocol DataStore {}
class CoreDataStore: DataStore {}
class AddEventWireframe {
    var eventsListWireframe: EventsListWireframe?
}
class EventsListWireframe {
    var addEventWireframe: AddEventWireframe?
    let dataStore: DataStore
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
}


let rootContainer = DependencyContainer()
rootContainer.register(.singleton) { CoreDataStore() as DataStore }

let eventsListModule = DependencyContainer()
eventsListModule.register { EventsListWireframe(dataStore: $0) }
    .resolvingProperties { container, wireframe in
        wireframe.addEventWireframe = try container.resolve()
}

let addEventModule = DependencyContainer()
addEventModule.register { AddEventWireframe() }

eventsListModule.collaborate(with: addEventModule, rootContainer)

var eventsListWireframe = try eventsListModule.resolve() as EventsListWireframe
eventsListWireframe.dataStore
eventsListWireframe.addEventWireframe

/*:
 As you can see dependencies were resolved even though not all components were registered in the same container.
 It is even safe to make circular references between containers. This way you can resolve circular dependencies between components registered in different containers.
 */

eventsListModule.reset()
addEventModule.reset()

eventsListModule.register { EventsListWireframe(dataStore: $0) }
    .resolvingProperties { container, wireframe in
        wireframe.addEventWireframe = try container.resolve()
}

addEventModule.register { AddEventWireframe() }
    .resolvingProperties { container, wireframe in
        wireframe.eventsListWireframe = try container.resolve()
}

addEventModule.collaborate(with: eventsListModule)

eventsListWireframe = try eventsListModule.resolve() as EventsListWireframe
eventsListWireframe.addEventWireframe
eventsListWireframe.addEventWireframe?.eventsListWireframe === eventsListWireframe

/*:
 If you try to link container with itself it will be silently ignored. When forwarding request collaborating containers will be iterated in the same order that they were added.
 */

//: [Next: Testing](@next)
