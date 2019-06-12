//#if _runtime(_ObjC)
  extension String {
    func has(prefix aPrefix: String) -> Bool {
      return hasPrefix(aPrefix)
    }
  }
//
//#else
//
//  extension String {
//    func has(prefix aPrefix: String) -> Bool {
//      return aPrefix == String(self.prefix(aPrefix.count))
//    }
//
//  }
//#endif
