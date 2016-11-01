# CHANGELOG

## 5.0.4

#### Fixed

* Fixed broken compatibility for Swift 2.3 API in `resolve(tag:arguments:)` method.
  [#135](https://github.com/AliSoftware/Dip/issues/135), [@ilyapuchka](https://github.com/ilyapuchka)
  
## 5.0.3

* Added Swift 2.3 compatibility. `swift2.3` brunch is no longer maintained.  
  [#127](https://github.com/AliSoftware/Dip/issues/127), [@ilyapuchka](https://github.com/ilyapuchka)

#### Fixed

* Fixed reusing instances registered with `WeakSingleton` scope  
  [#129](https://github.com/AliSoftware/Dip/issues/129), [@ilyapuchka](https://github.com/ilyapuchka)

## 5.0.2

#### Fixed

* Fixed Swift 3 issues related to reflection and IUO  
  [#125](https://github.com/AliSoftware/Dip/issues/125), [@ilyapuchka](https://github.com/ilyapuchka)

## 5.0.1

This release is the same as 5.0.0 and only fixes CocoaPods speck pushed to trunk without macOS, tvOS and watchOS deployment targets. Please use this release instead of 5.0.0 if you integrate Dip via Cocoapods.

## 5.0.0

* Migrated to Swift 3.0  
  [#120](https://github.com/AliSoftware/Dip/issues/120), [@patrick-lind](https://github.com/patrick-lind), [@mark-urbanthings](https://github.com/mark-urbanthings), [@ilyapuchka](https://github.com/ilyapuchka)
* Renamed `DefinitionOf` to `Definition` and some other source-breaking refactoring.  
  [#113](https://github.com/AliSoftware/Dip/issues/113), [@ilyapuchka](https://github.com/ilyapuchka)
* Added `invalidType` error when resolved instance does not implement requested type.  
  [#118](https://github.com/AliSoftware/Dip/issues/118), [@ilyapuchka](https://github.com/ilyapuchka)
* Added optional `type` parameter in register methods to be able to specify type when registering using method literal instead of closure.
  [#115](https://github.com/AliSoftware/Dip/issues/115), [@ilyapuchka](https://github.com/ilyapuchka)
* Added `implements` family of methods in to `Definition` to register type-forwarding definitions.  
  [#114](https://github.com/AliSoftware/Dip/issues/114), [@ilyapuchka](https://github.com/ilyapuchka)
* Shared scope is now the default scope.  
  [#112](https://github.com/AliSoftware/Dip/issues/112), [@ilyapuchka](https://github.com/ilyapuchka)
* Single target project setup.  
  [#121](https://github.com/AliSoftware/Dip/issues/121), [@ilyapuchka](https://github.com/ilyapuchka)
* Simplified implementation of auto-wiring.  
  [#117](https://github.com/AliSoftware/Dip/issues/117), [@ilyapuchka](https://github.com/ilyapuchka)


#### Fixed
* Auto-injected properties inherited from super class are now properly injected when resolving subclass. 
Added `resolveDependencies(_:DependencyContainer)` method to `Resolvable` protocol to handle inheritance when resolving.  
  [#116](https://github.com/AliSoftware/Dip/issues/116), [@ilyapuchka](https://github.com/ilyapuchka)
  
  
## 4.6.1

#### Fixed

* Fixed sharing singletons between collaborating containers.  
  [#103](https://github.com/AliSoftware/Dip/issues/103), [@ilyapuchka](https://github.com/ilyapuchka)
* Renamed some public API's (see release notes for more info).  
  [#105](https://github.com/AliSoftware/Dip/issues/105), [@ilyapuchka](https://github.com/ilyapuchka)

## 4.6.0

* Containers collaboration. Break your definitions in modules and link them together.  
  [#95](https://github.com/AliSoftware/Dip/pull/95), [@ilyapuchka](https://github.com/ilyapuchka)
* Added WeakSingleton scope.  
  [#96](https://github.com/AliSoftware/Dip/pull/96), [@ilyapuchka](https://github.com/ilyapuchka)
* Properties Auto-injection now is performed before calling `resolveDependencies` block  
  [#97](https://github.com/AliSoftware/Dip/pull/97), [@ilyapuchka](https://github.com/ilyapuchka)
* Fixed updating container's context when resolving properties with auto-injection.  
  [#98](https://github.com/AliSoftware/Dip/pull/98), [@ilyapuchka](https://github.com/ilyapuchka) 
* Improved logging.  
  [#94](https://github.com/AliSoftware/Dip/pull/94), [#99](https://github.com/AliSoftware/Dip/pull/99), [@ilyapuchka](https://github.com/ilyapuchka)
* Fixed warning about using only extensions api.  
  [#92](https://github.com/AliSoftware/Dip/pull/92), [@mwoollard](https://github.com/mwoollard)

## 4.5.0

* Added weakly-typed API to resolve components when exact type is unknown during compile time.  
  [#79](https://github.com/AliSoftware/Dip/pull/79), [@ilyapuchka](https://github.com/ilyapuchka)
* Added type forwarding feature. You can register the same factory to resolve different types.  
  [#89](https://github.com/AliSoftware/Dip/pull/89), [@ilyapuchka](https://github.com/ilyapuchka) 
* Container now can resolve optional types :tada:  
  [#84](https://github.com/AliSoftware/Dip/pull/84), [@ilyapuchka](https://github.com/ilyapuchka)
* Added container context that provides contextual information during graph resolution process.  
  [#83](https://github.com/AliSoftware/Dip/pull/83), [@ilyapuchka](https://github.com/ilyapuchka)
* Added method to validate container configuration.  
  [#87](https://github.com/AliSoftware/Dip/pull/87), [@ilyapuchka](https://github.com/ilyapuchka)
* Added method to manually set value wrapped by auto-injection wrappers.  
  [#81](https://github.com/AliSoftware/Dip/pull/81), [@ilyapuchka](https://github.com/ilyapuchka)
* Added separate error type for failures during auto-wiring.  
  [#85](https://github.com/AliSoftware/Dip/pull/85), [@ilyapuchka](https://github.com/ilyapuchka)


## 4.4.0

* Added `.EagerSingleton` scope for objectes requiring early instantiation and `bootstrap()` method on `DepenencyContainer`.  
  [#65](https://github.com/AliSoftware/Dip/pull/65), [@ilyapuchka](https://github.com/ilyapuchka)
* Reverted order of `Resolvable` callbacks.  
  [#67](https://github.com/AliSoftware/Dip/pull/67), [@ilyapuchka](https://github.com/ilyapuchka)

## 4.3.1

* Fix Swift 2.2 compile errors in tests.  
  [#62](https://github.com/AliSoftware/Dip/pull/62), [@mwoollard](https://github.com/mwoollard)

## 4.3.0

* Added `DependencyTagConvertible` protocol for better typed tags.  
  [#50](https://github.com/AliSoftware/Dip/pull/50), [@gavrix](https://github.com/gavrix)
* Auto-wiring. `DependencyContainer` resolves constructor arguments automatically.  
  [#55](https://github.com/AliSoftware/Dip/pull/55), [@ilyapuchka](https://github.com/ilyapuchka)
* Added `Resolvable` protocol to get a callback when dependencies graph is complete.  
  [#57](https://github.com/AliSoftware/Dip/pull/57), [@ilyapuchka](https://github.com/ilyapuchka)
* Removed `DipError.ResolutionFailed` error for better consistency.  
  [#58](https://github.com/AliSoftware/Dip/pull/58), [@ilyapuchka](https://github.com/ilyapuchka)


## 4.2.0

* Added support for Swift Package Manager.  
  [#41](https://github.com/AliSoftware/Dip/pull/41), [@ilyapuchka](https://github.com/ilyapuchka)
* Added Linux support.  
  [#42](https://github.com/AliSoftware/Dip/pull/42), [#46](https://github.com/AliSoftware/Dip/pull/46), [@ilyapuchka](https://github.com/ilyapuchka)
* Fixed the issue that could cause singleton instances to be reused between different containers.  
  [#43](https://github.com/AliSoftware/Dip/pull/43), [@ilyapuchka](https://github.com/ilyapuchka)
* Added public `AutoInjectedPropertyBox` protocol for user-defined auto-injected property wrappers.  
  [#49](https://github.com/AliSoftware/Dip/pull/49), [@ilyapuchka](https://github.com/ilyapuchka)


## 4.1.0

#### New features

* Added auto-injection feature.  
  [#13](https://github.com/AliSoftware/Dip/pull/13), [@ilyapuchka](https://github.com/ilyapuchka)
* Factories and `resolveDependencies` blocks of `DefinitionOf` are now allowed to `throw`. Improved errors handling.  
  [#32](https://github.com/AliSoftware/Dip/pull/32), [@ilyapuchka](https://github.com/ilyapuchka)
* Thread safety reimplemented with support for recursive methods calls.  
  [#31](https://github.com/AliSoftware/Dip/pull/31), [@mwoollard](https://github.com/mwoollard)


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
  container.register(tag: "some tag") { SomeClass() as SomeProtocol }
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
