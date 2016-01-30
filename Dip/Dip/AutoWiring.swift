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
    
    var autoWiringDefinitionsKeys = self.definitions
      //filter only definitions with auto-wiring factory
      .filter({ ($0.1 as? _Definition)?._autoWiringFactory != nil })
      .map({ $0.0 }) //get definition keys

    autoWiringDefinitionsKeys = autoWiringDefinitionsKeys
      //filter keys for T and factories with arguments
      .filter({ $0.protocolType == T.self && $0.numberOfArguments > 0 })
      //filter keys with the same or nil tag
      .filter({ $0.associatedTag == key.associatedTag || $0.associatedTag == nil })
      //sort filtered keys by number of factory arguments
      .sort({ $0.numberOfArguments > $1.numberOfArguments })
    
    guard !autoWiringDefinitionsKeys.isEmpty else { return nil }
    
    autoWiringDefinitionsKeys =
      //first we try tagged definitions
      autoWiringDefinitionsKeys.filter({ $0.associatedTag == key.associatedTag }) +
      //if non of them worked we fallback to not-tagged definitions
      autoWiringDefinitionsKeys.filter({ $0.associatedTag != key.associatedTag })
    
    return try _resolveEnumeratingKeys(autoWiringDefinitionsKeys, tag: key.associatedTag)
  }
  
  /// Tries definitions one by one until one of them succeeds, otherwise returns nil
  private func _resolveEnumeratingKeys<T>(keys: [DefinitionKey], tag: DependencyContainer.Tag?) throws -> T? {
    for (index, key) in keys.enumerate() {
      //if this and the next definition have the same number of arguments
      //we can not choose one of them
      if let
        nextKey = keys[next: index] where
        nextKey.numberOfArguments == key.numberOfArguments &&
        nextKey.associatedTag == key.associatedTag {
          throw DipError.AmbiguousDefinitions(key)
      }
      
      if let resolved: T = _resolveKey(key, tag: tag) {
        return resolved
      }
    }
    return nil
  }
  
  private func _resolveKey<T>(key: DefinitionKey, tag: DependencyContainer.Tag?) -> T? {
    do {
      let key = DefinitionKey(protocolType: key.protocolType, factoryType: key.factoryType, associatedTag: tag)
      
      return try _resolveKey(key, builder: { definition throws -> T in
        guard let resolved = try definition._autoWiringFactory!(self, tag) as? T else {
          fatalError("Internal inconsistency exception! Expected type: \(T.self); Definition: \(definition)")
        }
        return resolved
      })
    }
    catch {
      return nil
    }
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
