# CHANGELOG

## Develop

#### New features

* Added auto-injection feature.  
  [#13](https://github.com/AliSoftware/Dip/pull/13), [@ilyapuchka](https://github.com/ilyapuchka)
* Factories and `resolveDependencies` blocks of `DefinitionOf` are now allowed to `throw`.  
  [#32](https://github.com/AliSoftware/Dip/pull/32), [@ilyapuchka](https://github.com/ilyapuchka)
* Thread safety reimplemented with support for recursive methods calls.  
  [#31](https://github.com/AliSoftware/Dip/pull/31), [@mwoollard](https://github.com/mwoollard)
* Multi-injection to resolve an array of all the instances registere for the protocol.  
  [#39](https://github.com/AliSoftware/Dip/pull/39), [@ilyapuchka](https://github.com/ilyapuchka)


## 4.0.0

#### New Features

* Added support for circular dependencies:
    * Added `ObjectGraph` scope to reuse resolved instances 
    * Added `resolveDependencies` method on `DefinitionOf` class to resolve dependencies of resolved instance.  
  [#11](https://github.com/AliSoftware/Dip/pull/11), [@ilyapuchka](https://github.com/ilyapuchka)
* Added methods to register/remove individual definitions.  
  [#11](https://github.com/AliSoftware/Dip/pull/11), [@ilyapuchka](https://github.com/ilyapuchka)
* All `resolve` methods now can throw error if type can not be resolved.  
  [#15](https://github.com/AliSoftware/Dip/issues/15), [@ilyapuchka](https://github.com/ilyapuchka)
* `DependencyContainer` is marked as `final`.
* Added support for OSX, tvOS and watchOS2.  
  [#26](https://github.com/AliSoftware/Dip/pull/26), [@ilyapuchka](https://github.com/ilyapuchka)


#### Breaking Changes

* Removed container thread-safety to enable recursion calls to `resolve`.  
  **Access to container from multiple threads should be handled by clients** from now on.
* All `resolve` methods now can throw.

	### Note on migration from 3.x to 4.0.0:
	* Errors

	In 4.0.0 each `resolve` method can throw `DefinitionNotFound(DefinitionKey)` error, so you need to call it using `try!` or `try?`, or catch the error if it's appropriate for your case. See [#15](https://github.com/AliSoftware/Dip/issues/15) for rationale of this change.
	
	* Thread safety

	In 4.0.0 `DependencyContainer` drops any guarantee of thread safety. From now on code that uses Dip must ensure that it's methods are called from a single thread. For example if you have registered type as a singleton and later two threads try to resolve it at the same time you can have two different instances of type instead of one as expected. This change was required to enable recursive calls of `resolve` method to resolve circular dependencies.
	
	* Removed methods

	Methods deprecated in 3.1.0 are now removed.


## 3.1.0

#### New

* Added name for the first runtime argument in `resolve(tag:withArguments: … )` methods to make more clear separation between tag and factory runtime arguments.

#### Depreciations

* `resolve(tag:_: … )` methods are deprecated in favor of those new `resolve(tag:withArguments: … )` methods.
* Deprecated `register(tag:instance:)` method in favor of `register(.Singleton) { … }`.

## 3.0.0

* Added support for factories with up to six runtime arguments.  
  [#8](https://github.com/AliSoftware/Dip/pull/8), [@ilyapuchka](https://github.com/ilyapuchka)
* Parameter `tag` is now named in all register/resolve methods.
* Playground added to project.  
  [#10](https://github.com/AliSoftware/Dip/pull/10), [@ilyapuchka](https://github.com/ilyapuchka)
  
  ### Note on migration from 2.0.0 to 3.0.0:

  If you used tags to register and resolve your components you have to add `tag` name for tag parameter. Don't forget to add it both in `register` and `resolve` methods. If you forget to add it in `resolve` call then tag value will be treated as first runtime argument for a factory, but there is no such factory registerd, so resolve will fail.
  
  **Example**:
  
  This code: 
  
  ```swift
  container.register("some tag") { SomeClass() as SomeProtocol }
  container.resolve("some tag") as SomeProtocol
  ```
  
  becomes this:
  
  ```swift
  container.register(tag: "some tag") { SomeClass() as SomeProtocol }
  container.resolve(tag: "some tag") as SomeProtocol
  ```
  

## 2.0.0

* Moved from generic _tag_ parameter on container to `Tag` enum with `String` and `Int` cases  
[#3](https://github.com/AliSoftware/Dip/pull/3), [@ilyapuchka](https://github.com/ilyapuchka)

> This API change allows easier use of `DependencyContainer` and avoid some constraints. For a complete rationale on that change, see [PR #3](https://github.com/AliSoftware/Dip/pull/3).

## 1.0.1

* Improved README
* Imrpoved discoverability using keywords in `podspec`

## 1.0.0

#### Dip

* Added Unit Tests for `SWAPIPersonProvider` and `SWAPIStarshipProvider`

_All work in progress is now done. I consider `Dip` to be ready for production and with a stable API, hence the `1.0.0` version bump._

#### Example Project

* Using `func fetchIDs` and `func fetchOne` instead of `lazy var` for readability

## 0.1.0

#### Dip

* Dip is now Thread-Safe
* Added a configuration block so we can easily create the container and register the dependencies all in one expression:

```swift
let deps = DependencyContainer() {
  $0.register() { x as Foo }
  $0.register() { y as Bar }
  $0.register() { z as Baz }
}
```

* Source Documentation

#### Example Project

* Code Cleanup
* Added more values to `HardCodedStarshipProvider` so it works when the `PersonProviderAPI` uses real pilots from swapi.co (`SWAPIPersonProvider`)

## 0.0.4

#### Example Project

* Added `SWAPIPersonProvider` & `SWAPIStarshipProvider` that use http://swapi.co

## 0.0.3

#### Example Project

* Revamped the Sample project to a more complete example (using StarWars API!)
* Using Mixins & Traits in the Sample App for `FetchableTrait` and `FillableCell`

## 0.0.2

#### Dip

* Switched from class methods to instance methods ([#1](https://github.com/AliSoftware/Dip/issues/1)). This allows you to have multiple `DependencyContainers`
* Renamed the class from `Dependency` to `DependencyContainer`
* Renamed the `instanceFactory:` parameter to `factory:`
* Made the `DependencyContainer` generic of the type of _tag_. We are no longer limited to tags of type `String`, we can now use anything that's `Equatable`.

## 0.0.1

Initial version to release the early proof of concept.

Ready to use, but API may change, documentation and unit tests are missing, and thread-safety is not guaranteed.
