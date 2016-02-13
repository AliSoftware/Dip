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
typealias FileString = StaticString
#else
typealias FileString = String
#endif
  

func AssertThrows<T>(file: FileString = __FILE__, line: UInt = __LINE__, @autoclosure expression: () throws -> T) {
  AssertThrows(file, line: line, expression: expression, "")
}

func AssertThrows<T>(file: FileString = __FILE__, line: UInt = __LINE__, @autoclosure expression: () throws -> T, _ message: String) {
  AssertThrows(expression: expression, checkError: { _ in true }, message)
}

func AssertThrows<T>(file: FileString = __FILE__, line: UInt = __LINE__, @autoclosure expression: () throws -> T, checkError: ErrorType -> Bool) {
  AssertThrows(file, line: line, expression: expression, checkError: checkError, "")
}

func AssertThrows<T>(file: FileString = __FILE__, line: UInt = __LINE__, @autoclosure expression: () throws -> T, checkError: ErrorType -> Bool, _ message: String) {
  do {
    try expression()
    XCTFail(message, file: file, line: line)
  }
  catch {
    XCTAssertTrue(checkError(error), "Thrown unexpected error: \(error)")
  }
}

func AssertNoThrow<T>(file: FileString = __FILE__, line: UInt = __LINE__, @autoclosure expression: () throws -> T) {
  AssertNoThrow(file, line: line, expression: expression, "")
}

func AssertNoThrow<T>(file: FileString = __FILE__, line: UInt = __LINE__, @autoclosure expression: () throws -> T, _ message: String) {
  do {
    try expression()
  }
  catch {
    XCTFail(message, file: file, line: line)
  }
}

#if os(Linux)
import Glibc
typealias TMain = @convention(c) (UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void>

func dispatch_async(block: TMain) {
  var pid: pthread_t = 0
  pthread_create(&pid, nil, block, nil)
}

func dispatch_sync(block: TMain) -> UnsafeMutablePointer<Void> {
  var pid: pthread_t = 0
  var result: UnsafeMutablePointer<Void> = nil
  pthread_create(&pid, nil, block, nil)
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
