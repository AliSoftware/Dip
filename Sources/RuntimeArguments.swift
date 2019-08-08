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

extension DependencyContainer {
  
  /**
   Register factory for type `T` and associate it with an optional tag.
   
   - parameters:
      - scope: The scope to use for instance created by the factory. Default value is `Shared`.
      - type: Type to register definition for. Default value is return value of factory.
      - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
      - factory: The factory that produces instance of `type`. Will be used to resolve instances of `type`.
   
   - returns: A registered definition.
   
   - note: You should cast the factory return type to the protocol you want to register it for
           (unless you want to register concrete type) or provide `type` parameter.
   
   - seealso: `Definition`, `ComponentScope`, `DependencyTagConvertible`
   
   **Example**:
   ```swift
   //Register ServiceImp as Service
   container.register { ServiceImp() as Service }
   
   //Register ServiceImp as Service named by "service"
   container.register(tag: "service") { ServiceImp() as Service }
   
   //Register unique ServiceImp as Service
   container.register(.unique) { ServiceImp() as Service }
   
   //Register ClientImp as Client and resolve it's service dependency
   container.register { try ClientImp(service: container.resolve() as Service) as Client }
   
   //Register ServiceImp as concrete type
   container.register { ServiceImp() }
   container.register(factory: ServiceImp.init)
   
   //Register ServiceImp as Service
   container.register(Service.self, factory: ServiceImp.init)
   
   //Register ClientImp as Client
   container.register(Client.self, factory: ClientImp.init(service:))
   ```
   */
  @discardableResult public func register<T>(_ scope: ComponentScope = .shared, type: T.Type = T.self, tag: DependencyTagConvertible? = nil, factory: @escaping (()) throws -> T) -> Definition<T, ()> {
    let definition = DefinitionBuilder<T, ()> {
      $0.scope = scope
      $0.factory = factory
      }.build()
    register(definition, tag: tag)
    return definition
  }
  
  /**
   Register generic factory and auto-wiring factory and associate it with an optional tag.
   
   - parameters:
      - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
      - scope: The scope to use for instance created by the factory.
      - factory: The factory to register.
      - numberOfArguments: The number of factory arguments. Will be used on auto-wiring to sort definitions.
      - autoWiringFactory: The factory to be used on auto-wiring to resolve component.
   
   - returns: A registered definition.
   
   - note: You _should not_ call this method directly, instead call any of other `register` methods.
           You _should_ use this method only to register dependency with more runtime arguments
           than _Dip_ supports (currently it's up to six) like in the following example:
   
   ```swift
   public func register<T, A, B, C, ...>(_ scope: ComponentScope = .shared, type: T.Type = T.self, tag: Tag? = nil, factory: (A, B, C, ...) throws -> T) -> Definition<T, (A, B, C, ...)> {
     return register(scope: scope, type: type, tag: tag, factory: factory, numberOfArguments: ...) { container, tag in
       try factory(container.resolve(tag: tag), ...)
     }
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce number of depnedencies.
   */
  public func register<T, U>(scope: ComponentScope, type: T.Type, tag: DependencyTagConvertible?, factory: @escaping (U) throws -> T, numberOfArguments: Int, autoWiringFactory: @escaping (DependencyContainer, Tag?) throws -> T) -> Definition<T, U> {
    let definition = DefinitionBuilder<T, U> {
      $0.scope = scope
      $0.factory = factory
      $0.numberOfArguments = numberOfArguments
      $0.autoWiringFactory = autoWiringFactory
      }.build()
    register(definition, tag: tag)
    return definition
  }

}
