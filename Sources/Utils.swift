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

public enum LogLevel {
  case Verbose
  case Errors
  case None
}
public var logLevel: LogLevel = .Errors

func log(_ logLevel: LogLevel, _ message: Any) {
  guard case logLevel = Dip.logLevel else { return }
  print(message)
}

///Internal protocol used to unwrap optional values.
protocol BoxType {
  var unboxed: Any? { get }
}

extension Optional: BoxType {
  var unboxed: Any? {
    switch self {
    case let .some(value): return value
    default: return nil
    }
  }
}

extension ImplicitlyUnwrappedOptional: BoxType {
  var unboxed: Any? {
    switch self {
    case let .some(value): return value
    default: return nil
    }
  }
}

protocol WeakBoxType {
  var unboxed: AnyObject? { get }
}

class WeakBox<T>: WeakBoxType {
  weak var unboxed: AnyObject?
  var value: T? {
    return unboxed as? T
  }

  init(value: T) {
    guard let value = value as? AnyObject else {
      fatalError("Can not store weak reference to not a class instance (\(T.self))")
    }
    self.unboxed = value
  }
}

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

extension Collection where Index: Comparable, Self.Indices.Index == Index {
  subscript(safe index: Index) -> Generator.Element? {
    guard indices.startIndex..<indices.endIndex ~= index else { return nil }
    return self[index]
  }
  subscript(next index: Index) -> Generator.Element? {
    return self[safe: indices.index(after: index)]
  }
}

#if os(Linux)
  import Glibc
  class RecursiveLock {
    private var _lock = _initializeRecursiveMutex()
    
    func lock() {
      _lock.lock()
    }
    
    func unlock() {
      _lock.unlock()
    }
    
    deinit {
      pthread_mutex_destroy(&_lock)
    }
    
  }
  
  private func _initializeRecursiveMutex() -> pthread_mutex_t {
    var mutex: pthread_mutex_t = pthread_mutex_t()
    var mta: pthread_mutexattr_t = pthread_mutexattr_t()
    pthread_mutexattr_init(&mta)
    pthread_mutexattr_settype(&mta, Int32(PTHREAD_MUTEX_RECURSIVE))
    pthread_mutex_init(&mutex, &mta)
    return mutex
  }
  
  extension pthread_mutex_t {
    mutating func lock() {
      pthread_mutex_lock(&self)
    }
    mutating func unlock() {
      pthread_mutex_unlock(&self)
    }
  }
  
#else
  import Foundation
  typealias RecursiveLock = NSRecursiveLock
#endif
