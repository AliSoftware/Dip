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

protocol TypeForwardingDefinition: DefinitionType {
  var implementingTypes: [Any.Type] { get }
  func doesImplements(type: Any.Type) -> Bool
}

extension Definition {
  
  /**
   Registers definition for passed type.
   
   If instance created by factory of definition on which method is called 
   does not implement type passed in a `type` parameter,
   container will throw `DipError.DefinitionNotFound` error when trying to resolve that type.
   
   - parameters:
      - type: Type to register definition for
      - tag: Optional tag to associate definition with. Default is `nil`.
   
   - returns: definition on which `implements` was called
   */
  public func implements<F>(type: F.Type, tag: DependencyTagConvertible? = nil) -> Definition {
    precondition(container != nil, "Definition should be registered in the container.")

    container!.register(self, type: type, tag: tag)
    return self
  }
  
  /**
   Registers definition for passed type.
   
   If instance created by factory of definition on which method is called
   does not implement type passed in a `type` parameter,
   container will throw `DipError.DefinitionNotFound` error when trying to resolve that type.
   
   - parameters:
      - type: Type to register definition for
      - tag: Optional tag to associate definition with. Default is `nil`.
      - resolvingProperties: Optional block to be called to resolve instance property dependencies
   
   - returns: definition on which `implements` was called
   */
  public func implements<F>(type: F.Type, tag: DependencyTagConvertible? = nil, resolvingProperties: (DependencyContainer, F) throws -> ()) -> Definition {
    precondition(container != nil, "Definition should be registered in the container.")
    
    let forwardDefinition = container!.register(self, type: type, tag: tag)
    forwardDefinition.resolvingProperties(resolvingProperties)
    return self
  }

  ///Registers definition for types passed as parameters
  public func implements<A, B>(a: A.Type, _ b: B.Type) -> Definition {
    return implements(a).implements(b)
  }

  ///Registers definition for types passed as parameters
  public func implements<A, B, C>(a: A.Type, _ b: B.Type, _ c: C.Type) -> Definition {
    return implements(a).implements(b).implements(c)
  }

  ///Registers definition for types passed as parameters
  public func implements<A, B, C, D>(a: A.Type, _ b: B.Type, c: C.Type, d: D.Type) -> Definition {
    return implements(a).implements(b).implements(c).implements(d)
  }

}

extension DependencyContainer {
  
  /**
   Registers definition for passed type.
   
   If instance created by factory of definition, passed as a first parameter,
   does not implement type passed in a `type` parameter,
   container will throw `DipError.DefinitionNotFound` error when trying to resolve that type.
   
   - parameters:
      - definition: Definition to register
      - type: Type to register definition for
      - tag: Optional tag to associate definition with. Default is `nil`.
   
   - returns: New definition registered for passed type.
   */
  public func register<T, U, F>(definition: Definition<T, U>, type: F.Type, tag: DependencyTagConvertible? = nil) -> Definition<F, U> {
    precondition(definition.container === self, "Definition should be registered in the container.")
    
    let key = DefinitionKey(type: F.self, typeOfArguments: U.self)
    
    let forwardDefinition = DefinitionBuilder<F, U> {
      $0.scope = definition.scope
      
      let factory = definition.factory
      $0.factory = { [unowned self] in
        guard let resolved = try factory($0) as? F else {
          throw DipError.DefinitionNotFound(key: key.tagged(self.context.tag))
        }
        return resolved
      }

      $0.numberOfArguments = definition.numberOfArguments
      $0.autoWiringFactory = definition.autoWiringFactory.map({ autoWiringFactory in
        { [unowned self] in
          guard let resolved = try autoWiringFactory($0, $1) as? F else {
            throw DipError.DefinitionNotFound(key: key.tagged(self.context.tag))
          }
          return resolved
        }
      })
      $0.forwardsTo = definition
      }.build()
    
    register(forwardDefinition, forTag: tag)
    return forwardDefinition
  }
  
  /// Searches for definition that forwards requested type
  func typeForwardingDefinition(key: DefinitionKey) -> KeyDefinitionPair? {
    var forwardingDefinitions = self.definitions.map({ (key: $0.0, definition: $0.1) })
    
    forwardingDefinitions = filter(forwardingDefinitions, byKey: key, byTypeOfArguments: true)
    forwardingDefinitions = order(forwardingDefinitions, byTag: key.tag)

    //we need to carry on original tag
    return forwardingDefinitions.first.map({ ($0.key.tagged(key.tag), $0.definition) })
  }
  
}
