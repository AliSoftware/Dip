//
// Dip
//
// Copyright (c) 2015 Olivier Halligon <olivier@halligon.net>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

// MARK: - Register/resolve dependencies with runtime arguments

extension DependencyContainer {
  
  // MARK: 1 Runtime Argument
  
  /**
  Register factory that accepts one runtime argumentof type `Arg1`. You can use up to six runtime arguments.

  - note: You can have several factories with different number or types of arguments registered for same type,
          optionally associated with some tags. When container resolves that type it matches the type,
          __number__, __types__ and __order__ of runtime arguments and optional tag that you pass to `resolve(tag:withArguments:)` method.

  - parameters:
    - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
    - scope: The scope to use for this component. Default value is `.Prototype`.
    - factory: The factory to register.
  
  - seealso: `registerFactory(tag:scope:factory:)`
  */
  public func register<T, Arg1>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: (Arg1) throws -> T) -> DefinitionOf<T, (Arg1) throws -> T> {
    return registerFactory(tag: tag, scope: scope, factory: factory)
  }
  
  /**
   Resolve a dependency using one runtime argument.
   
   - parameters:
      - tag: The arbitrary tag to lookup registered definition.
      - arg1: The first argument to pass to the definition's factory.
   
   - throws: An error of type `DipError`:
             `ResolutionFailed` - if some error was thrown during resolution;
             `DefinitionNotFound` - if no matching definition was registered in that container.

   - returns: An instance of type `T`.

   - seealso: `register(tag:_:factory:)`, `resolve(tag:builder:)`
   */
  public func resolve<T, Arg1>(tag tag: Tag? = nil, withArguments arg1: Arg1) throws -> T {
    return try resolve(tag: tag) { (factory: (Arg1) throws -> T) in try factory(arg1) }
  }
  
  // MARK: 2 Runtime Arguments
  
  /// - seealso: `register(tag:scope:factory:)`
  public func register<T, Arg1, Arg2>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: (Arg1, Arg2) throws -> T) -> DefinitionOf<T, (Arg1, Arg2) throws -> T> {
    return registerFactory(tag: tag, scope: scope, factory: factory)
  }
  
  /// - seealso: `resolve(tag:_:)`
  public func resolve<T, Arg1, Arg2>(tag tag: Tag? = nil, withArguments arg1: Arg1, _ arg2: Arg2) throws -> T {
    return try resolve(tag: tag) { (factory: (Arg1, Arg2) throws -> T) in try factory(arg1, arg2) }
  }

  // MARK: 3 Runtime Arguments
  
  /// - seealso: `register(tag:scope:factory:)`
  public func register<T, Arg1, Arg2, Arg3>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: (Arg1, Arg2, Arg3) throws -> T) -> DefinitionOf<T, (Arg1, Arg2, Arg3) throws -> T> {
    return registerFactory(tag: tag, scope: scope, factory: factory)
  }
  
  /// - seealso: `resolve(tag:withArguments:)`
  public func resolve<T, Arg1, Arg2, Arg3>(tag tag: Tag? = nil, withArguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) throws -> T {
    return try resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3) throws -> T) in try factory(arg1, arg2, arg3) }
  }
  
  // MARK: 4 Runtime Arguments
  
  /// - seealso: `register(tag:scope:factory:)`
  public func register<T, Arg1, Arg2, Arg3, Arg4>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: (Arg1, Arg2, Arg3, Arg4) throws -> T) -> DefinitionOf<T, (Arg1, Arg2, Arg3, Arg4) throws -> T> {
    return registerFactory(tag: tag, scope: scope, factory: factory)
  }
  
  /// - seealso: `resolve(tag:withArguments:)`
  public func resolve<T, Arg1, Arg2, Arg3, Arg4>(tag tag: Tag? = nil, withArguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4) throws -> T {
    return try resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, Arg4) throws -> T) in try factory(arg1, arg2, arg3, arg4) }
  }

  // MARK: 5 Runtime Arguments
  
  /// - seealso: `register(tag:scope:factory:)`
  public func register<T, Arg1, Arg2, Arg3, Arg4, Arg5>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: (Arg1, Arg2, Arg3, Arg4, Arg5) throws -> T) -> DefinitionOf<T, (Arg1, Arg2, Arg3, Arg4, Arg5) throws -> T> {
    return registerFactory(tag: tag, scope: scope, factory: factory)
  }
  
  /// - seealso: `resolve(tag:withArguments:)`
  public func resolve<T, Arg1, Arg2, Arg3, Arg4, Arg5>(tag tag: Tag? = nil, withArguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5) throws -> T {
    return try resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, Arg4, Arg5) throws -> T) in try factory(arg1, arg2, arg3, arg4, arg5) }
  }

  // MARK: 6 Runtime Arguments
  
  /// - seealso: `register(tag:scope:factory:)`
  public func register<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) throws -> T) -> DefinitionOf<T, (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) throws -> T> {
    return registerFactory(tag: tag, scope: scope, factory: factory)
  }
  
  /// - seealso: `resolve(tag:withArguments:)`
  public func resolve<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(tag tag: Tag? = nil, withArguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6) throws -> T {
    return try resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) throws -> T) in try factory(arg1, arg2, arg3, arg4, arg5, arg6) }
  }

}
