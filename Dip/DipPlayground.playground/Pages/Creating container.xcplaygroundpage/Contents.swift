//: [Previous](@previous)

import Dip

/*:
Dip has two base components: _container_ and _definition_. _Container_ is used to register _definitions_ and to resolve them. _Definitions_ describe how component should be created by _container_.

### Creating container

You can create container using `init()`:
*/

var container = DependencyContainer()
//register components here

/*:
or using configuration block:
*/

container = DependencyContainer { container in
    //register components here
}

//: [Next](@next)
