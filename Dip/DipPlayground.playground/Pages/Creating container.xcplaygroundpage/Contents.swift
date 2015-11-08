//: [Previous: What is Dip?](@previous)

import Dip

/*:
Dip has two base components: a _DependencyContainer_ and its _Definitions_.

 - _DependencyContainer_ is used to register _Definitions_ and to resolve them.
 - _Definitions_ describe how component should be created by the _DependencyContainer_.

### Creating the container

You can create a container using a simple `init()`:
*/

var container = DependencyContainer()
//register components here

/*:
or using a configuration block:
*/

container = DependencyContainer { container in
    //register components here
}

/*:
Both syntaxes are equivalent. The one using the configuration block is simply a convenience way to scope your components registrations in a nice looking way.
*/
//: [Next: Registering Components](@next)
