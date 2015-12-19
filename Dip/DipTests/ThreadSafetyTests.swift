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
@testable import Dip

class ThreadSafetyTests: XCTestCase {
  
  let container = DependencyContainer()
  
  override func setUp() {
    super.setUp()
    container.reset()
  }
  
  func testSingletonThreadSafety() {
    
    container.register(.Singleton) { ServiceImp1() as Service }
    
    let queue = NSOperationQueue()
    let lock = NSRecursiveLock()
    var resultSet = Set<ServiceImp1>()
    
    for _ in 1...100 {
      queue.addOperationWithBlock {
        let serviceInstance = try! self.container.resolve() as Service
        
        lock.lock()
        resultSet.insert(serviceInstance as! ServiceImp1)
        lock.unlock()
      }
    }
    
    queue.waitUntilAllOperationsAreFinished()
    
    XCTAssertEqual(resultSet.count, 1)
  }

  func testFactoryThreadSafety() {
    
    container.register() { ServiceImp1() as Service }
    
    let queue = NSOperationQueue()
    let lock = NSRecursiveLock()
    var resultSet = Set<ServiceImp1>()
    
    for _ in 1...100 {
      queue.addOperationWithBlock {
        let serviceInstance = try! self.container.resolve() as Service
        
        lock.lock()
        resultSet.insert(serviceInstance as! ServiceImp1)
        lock.unlock()
      }
    }
    
    queue.waitUntilAllOperationsAreFinished()
    
    XCTAssertEqual(resultSet.count, 100)
  }
  
  func testCircularReferenceThreadSafety() {
    //given
    container.register(.ObjectGraph) { Client(server: try! self.container.resolve()) as Client }
    
    container.register(.ObjectGraph) { Server() as Server }.resolveDependencies { container, server in
      server.client = try! container.resolve() as Client
    }

    let queue = NSOperationQueue()

    for _ in 1...100 {
      queue.addOperationWithBlock {
        //when
        let client = try! self.container.resolve() as Client

        //then
        let server = client.server
        XCTAssertTrue(server.client === client)
      }
    }

    queue.waitUntilAllOperationsAreFinished()
  }
  
  func testThreadSafetyPerformance() {
    container.register() { ServiceImp1() as Service }

    measureBlock() {
      for _ in 1...10000 {
        let _ = try! self.container.resolve() as Service
      }
    }
  }
  
  func testNoThreadSafetyPerformance() {
    let unsafeContainer = DependencyContainer(isThreadSafe:false)
    unsafeContainer.register() { ServiceImp1() as Service }
    
    measureBlock() {
      for _ in 1...10000 {
        let _ = try! unsafeContainer.resolve() as Service
      }
    }
  }
  
  func testNSRecursiveLockPerformance() {
    
    let lock = NSRecursiveLock()
    
    measureBlock() {
      for _ in 1...1000000 {
        lock.lock()
        lock.unlock()
      }
    }
  }
  
  func testObjcSyncEnterExitPerformance() {
    
    measureBlock() {
      for _ in 1...1000000 {
        objc_sync_enter(self)
        objc_sync_exit(self)
      }
    }
    
  }
}