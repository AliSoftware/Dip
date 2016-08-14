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
    //do not forget to use unowned reference if you will need
    //to reference container inside definition's factory
    unowned let container = container
    //register components here
}

/*:
Both syntaxes are equivalent. The one using the configuration block is simply a convenience way to scope your components registrations in a nice looking way.

### When/where to create container?

While there is an option to use container as a global variable we advise instead to create and configure container in your app delegate and pass it between your objects (see [Shared Instances](Shared%20Instances)).

*/
//: [Next: Registering Components](@next)
