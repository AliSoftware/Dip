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

import Foundation

extension Dictionary {
  subscript(key: Key?) -> Value? {
    get {
      guard let key = key else { return nil }
      return self[key]
    }
    set {
      guard let key = key else { return }
      self[key] = newValue
    }
  }
}

extension Optional {
  var desc: String {
    return self.map { "\($0)" } ?? "nil"
  }
}

extension String {
  func match(pattern: String) throws -> [String]? {
    let expr = try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions())
    let result = expr.firstMatchInString(self, options: NSMatchingOptions(), range: NSMakeRange(0, characters.count))
    return result?.allRanges.flatMap(safeSubstringWithRange)
  }
  
  func safeSubstringWithRange(range: NSRange) -> String? {
    if NSMaxRange(range) <= self.characters.count {
      return (self as NSString).substringWithRange(range)
    }
    return nil
  }
}

extension NSTextCheckingResult {
  var allRanges: [NSRange] {
    return (0..<numberOfRanges).map(rangeAtIndex)
  }
}
