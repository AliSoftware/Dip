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

import XCTest

#if os(Linux)
  typealias NSObject = AnyObject
#endif

func AssertThrows<T>(_ file: StaticString = #file, line: UInt = #line, expression: @autoclosure () throws -> T) {
  AssertThrows(file, line: line, expression: expression, "")
}

func AssertThrows<T>(_ file: StaticString = #file, line: UInt = #line, expression: @autoclosure () throws -> T, _ message: String) {
  AssertThrows(expression: expression, checkError: { _ in true }, message)
}

func AssertThrows<T>(_ file: StaticString = #file, line: UInt = #line, expression: @autoclosure () throws -> T, checkError: (Error) -> Bool) {
  AssertThrows(file, line: line, expression: expression, checkError: checkError, "")
}

func AssertThrows<T>(_ file: StaticString = #file, line: UInt = #line, expression: @autoclosure () throws -> T, checkError: (Error) -> Bool, _ message: String) {
  do {
    let _ = try expression()
    XCTFail(message, file: file, line: line)
  }
  catch {
    XCTAssertTrue(checkError(error), "Thrown unexpected error: \(error)", file: file, line: line)
  }
}

func AssertNoThrow<T>(_ file: StaticString = #file, line: UInt = #line, expression: @autoclosure () throws -> T) {
  AssertNoThrow(file, line: line, expression: expression, "")
}

func AssertNoThrow<T>(_ file: StaticString = #file, line: UInt = #line, expression: @autoclosure () throws -> T, _ message: String) {
  do {
    let _ = try expression()
  }
  catch {
    XCTFail(message, file: file, line: line)
  }
}

#if os(Linux)
import Glibc
typealias TMain = @convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?

private func startThread(_ block: @escaping TMain) -> pthread_t  {
  var pid: pthread_t = 0
  pthread_create(&pid, nil, block, nil)
  return pid
}

func dispatch_async(block: @escaping TMain) -> pthread_t {
  return startThread(block)
}

func dispatch_sync(block: @escaping TMain) -> UnsafeMutableRawPointer? {
  var result: UnsafeMutableRawPointer? = UnsafeMutableRawPointer.allocate(bytes: 1, alignedTo: 0)
  let pid = startThread(block)
  pthread_join(pid, &result)
  return result
}

extension pthread_spinlock_t {
  mutating func lock() {
    pthread_spin_lock(&self)
  }
  mutating func unlock() {
    pthread_spin_unlock(&self)
  }
}
#endif
