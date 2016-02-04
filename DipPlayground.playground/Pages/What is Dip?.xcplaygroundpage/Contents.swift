/*:
 __Note__: _This playground needs to be open as part of the `Dip.xcworkspace` so it can import the Dip framework / module and demonstrate its usage. (The playground won't work properly if you open it on its own)._

  _You might also need to ask Xcode to build the Dip framework first (Command-B) before it can find and import it in this playground._
*/

/*:
## What is Dip?

_Dip_ is a lightweight Swift implementation of [IoC container](https://en.wikipedia.org/wiki/Inversion_of_control).

If you follow [Protocol-Oriented programming](https://developer.apple.com/videos/play/wwdc2015-408/) or [SOLID principles](http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod) then instead of concrete classes you should use protocols to define dependencies between components of your system. I.e. if you need to access some network API, you should use instances of an `APIClient` protocol instead of instances of a concrete class `APIClientImp`.

[Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection) is a good tool to leverage Protocol-Oriented or SOLID design. Using this principle, you move the point where you create concrete instances _from inside objects_ that use them, _to higher levels_ of your system. **Now your objects do not depend on concrete implementations of their dependencies**, they depend **only on their public interfaces**, defined by protocols that they implement. That gives you all sorts of advantages from **easier testability** to **greater flexibility** of your system.

But still there should be some point in your program where concrete instances are created. The thing is that it's better to have one well defined point for that than to scatter setup logic all over the place with different factories and lazy properties. IoC containers like _Dip_ play the role of that point.

The following pages in this Playground demonstrates how to use _Dip_ to adopt all those concepts in practice.

If you want to know more about Dependency Injection in general we recomend you to read ["Dependency Injection in .Net" by Mark Seemann](https://www.manning.com/books/dependency-injection-in-dot-net). Dip was inspired by implementations of IoC container for .Net platform and shares core principles described in that book.

*/
//: [Next: Creating a DependencyContainer](@next)

