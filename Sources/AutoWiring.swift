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
  
  /// Tries to resolve instance using auto-wire factories
  func _resolveByAutoWiring<T>(key: DefinitionKey) throws -> T? {
    typealias NoArgumentsFactory = () throws -> T
    guard key.factoryType == NoArgumentsFactory.self else { return nil }
    
    let autoWiringDefinitions = self.autoWiringDefinitionsFor(T.self, tag: key.associatedTag)
    return try _resolveEnumeratingKeys(autoWiringDefinitions, tag: key.associatedTag)
  }
  
  private func autoWiringDefinitionsFor(type: Any.Type, tag: DependencyContainer.Tag?) -> [(DefinitionKey, _Definition)] {
    var definitions = self.definitions
      .map({ ($0.0, $0.1 as! _Definition) })
    
    //filter definitions
    definitions =  definitions
      .filter({ $0.1.supportsAutoWiring() })
      .filter({ $0.0.protocolType == type })
      .filter({ $0.0.associatedTag == tag || $0.0.associatedTag == nil })
    
    //order definitions
    definitions = definitions
      .sort({ $0.1.numberOfArguments > $1.1.numberOfArguments })

    definitions =
      //first will try to use tagged definitions
      definitions.filter({ $0.0.associatedTag == tag }) +
      //then will use not tagged definitions
      definitions.filter({ $0.0.associatedTag != tag })

    return definitions
  }
  
  /// Tries definitions one by one until one of them succeeds, otherwise returns nil
  private func _resolveEnumeratingKeys<T>(definitions: [(DefinitionKey, _Definition)], tag: DependencyContainer.Tag?) throws -> T? {
    for (index, definition) in definitions.enumerate() {
      //If the next definition matches current definition then they are ambigous
      if case definition? = definitions[next: index] {
          throw DipError.AmbiguousDefinitions(
            type: definition.0.protocolType,
            definitions: [definition.1, definitions[next: index]!.1]
        )
      }
      
      if let resolved: T = _resolveKey(definition.0, tag: tag) {
        return resolved
      }
    }
    return nil
  }
  
  private func _resolveKey<T>(key: DefinitionKey, tag: DependencyContainer.Tag?) -> T? {
    let key = DefinitionKey(protocolType: key.protocolType, factoryType: key.factoryType, associatedTag: tag)

    return try? _resolveKey(key, builder: { definition throws -> T in
      guard let resolved = try definition._autoWiringFactory!(self, tag) as? T else {
        fatalError("Internal inconsistency exception! Expected type: \(T.self); Definition: \(definition)")
      }
      return resolved
    })
  }
  
}

extension CollectionType {
  subscript(safe index: Index) -> Generator.Element? {
    guard indices.contains(index) else { return nil }
    return self[index]
  }
  subscript(next index: Index) -> Generator.Element? {
    return self[safe: index.advancedBy(1)]
  }
}

/// Definitions are matched if they are registered for the same tag and thier factoris accept the same number of runtime arguments.
private func ~=(lhs: (DefinitionKey, _Definition), rhs: (DefinitionKey, _Definition)) -> Bool {
  return
    lhs.0.protocolType == rhs.0.protocolType &&
      lhs.0.associatedTag == rhs.0.associatedTag &&
      lhs.1.numberOfArguments == rhs.1.numberOfArguments
}
