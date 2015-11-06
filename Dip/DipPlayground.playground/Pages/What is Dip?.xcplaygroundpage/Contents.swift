/*:
## Dip

_Dip_ is a lightweight Swift implementation of [IoC container](https://en.wikipedia.org/wiki/Inversion_of_control).

If you follow [Protocol-Oriented programming](https://developer.apple.com/videos/play/wwdc2015-408/) or [SOLID principles](http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod) then instead of concrete classes you should use protocols to define dependencies between components of your system. I.e. if you need to access some network API you should use instances of `APIClient` protocol instead of instances of concrete class `APIClientImp`. [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection) is a good tool to leverage Protocol-Oriented or SOLID design. Using this principle you move the point where you create concrete instaces from inside objects that use them to higher levels of your system. Now your objects do not depend on concrete implementations of their dependencies, they only depend on their public interfaces, defined by protocols that they implement. That gives you all sorts of advantages from easier testability to greater flexibility of your system.

But still there should be some point in your program where concrete instances are created. The thing is that it's better to have one well defined point for that than to scatter setup logic all over the place with different factories and lazy properties. IoC containers play the role of that point.

*/
//: [Next](@next)

