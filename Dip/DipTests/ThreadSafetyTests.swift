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
    
    let queue = NSOperationQueue()
    let lock = NSRecursiveLock()
    var resultSet = Set<ServiceImp1>()
    
    container.register(.Singleton) { ServiceImp1() as Service }
    
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
    
    let queue = NSOperationQueue()
    let lock = NSRecursiveLock()
    var resultSet = Set<ServiceImp1>()
    
    container.register() { ServiceImp1() as Service }
    
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

    let queue = NSOperationQueue()
    let lock = NSLock()
    
    container.register(.ObjectGraph) {
      Client(server: try! self.container.resolve()) as Client
    }
    
    container.register(.ObjectGraph) { Server() as Server }.resolveDependencies { container, server in
      var client: Client?
      dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        client = try! container.resolve() as Client
      }
      server.client = client!
    }

    var results = Array<Client>()

    for _ in 1...100 {
      queue.addOperationWithBlock {
        //when
        let client = try! self.container.resolve() as Client

        lock.lock()
        results.append(client)
        lock.unlock()
      }
    }

    queue.waitUntilAllOperationsAreFinished()

    for client in results {
      let server = client.server
      XCTAssertTrue(server.client === client)
    }
  }
  
}