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

private protocol Server: class {
  var client: Client! { get set }
}

private protocol Client: class {
  var server: Server { get }
}

private class ClientImp: Client, Equatable {
  var server: Server
  init(server: Server) {
    self.server = server
  }
}

private func ==<T: ClientImp>(lhs: T, rhs: T) -> Bool {
  return lhs === rhs
}

private class ServerImp: Server, Hashable {
  weak var client: Client!
  init() {}
  
  var hashValue: Int {
    return Unmanaged.passUnretained(self).toOpaque().hashValue
  }
}

private func ==<T: ServerImp>(lhs: T, rhs: T) -> Bool {
  return lhs === rhs
}

private var resolvedServers = Set<ServerImp>()
private var resolvedClients = Array<ClientImp>()

private var container: DependencyContainer!

#if os(Linux)
import Glibc
  
private var runningThreads: Int = 0
private var lock: pthread_spinlock_t = 0

private let resolveClientSync: () -> Client? = {
  let pointer = dispatch_sync { _ in
    let resolved = try! container.resolve() as Client
    return UnsafeMutableRawPointer(Unmanaged.passRetained(resolved as! ClientImp).toOpaque())
  }
  guard let clientPointer = pointer else { return nil }
  return Unmanaged<ClientImp>.fromOpaque(clientPointer).takeRetainedValue()
}
  
#else
let queue = OperationQueue()
let lock = RecursiveLock()
  
private let resolveClientSync: () -> Client? = {
  var client: Client?
  DispatchQueue.global(qos: .default).sync() {
    client = try! container.resolve() as Client
  }
  return client
}
  
#endif

let resolveServerAsync = {
  let server = try! container.resolve() as Server
  lock.lock()
  resolvedServers.insert(server as! ServerImp)

  #if os(Linux)
    runningThreads -= 1
  #endif

  lock.unlock()
}

let resolveClientAsync = {
  let client = try! container.resolve() as Client
  lock.lock()
  resolvedClients.append(client as! ClientImp)

  #if os(Linux)
    runningThreads -= 1
  #endif

  lock.unlock()
}

class ThreadSafetyTests: XCTestCase {
  
  #if os(Linux)
  required init(name: String, testClosure: @escaping (XCTestCase) throws -> Void) {
    pthread_spin_init(&lock, 0)
    super.init(name: name, testClosure: testClosure)
  }
  #endif
  
  static var allTests = {
    return [
      ("testSingletonThreadSafety", testSingletonThreadSafety),
      ("testFactoryThreadSafety", testFactoryThreadSafety),
      ("testCircularReferenceThreadSafety", testCircularReferenceThreadSafety)
    ]
  }()
  
  override func setUp() {
    Dip.logLevel = .Verbose
    container = DependencyContainer()
  }
  
  override func tearDown() {
    resolvedServers.removeAll()
    resolvedClients.removeAll()
  }
  
  func testSingletonThreadSafety() {
    container.register(.singleton) { ServerImp() as Server }
    
    for _ in 0..<100 {
      #if os(Linux)
      lock.lock()
      runningThreads += 1
      lock.unlock()
        
      dispatch_async { _ in
        resolveServerAsync()
        return nil
      }
      #else
      queue.addOperation(resolveServerAsync)
      #endif
    }
    
    #if os(Linux)
    while runningThreads > 0 { sleep(1) }
    #else
    queue.waitUntilAllOperationsAreFinished()
    #endif
    
    XCTAssertEqual(resolvedServers.count, 1, "Should create only one instance")
  }
  
  
  func testFactoryThreadSafety() {
    container.register { ServerImp() as Server }
    
    for _ in 0..<100 {
      #if os(Linux)
      lock.lock()
      runningThreads += 1
      lock.unlock()

      dispatch_async { _ in
        resolveServerAsync()
        return nil
      }
      #else
      queue.addOperation(resolveServerAsync)
      #endif
    }
    
    #if os(Linux)
    while runningThreads > 0 { sleep(1) }
    #else
    queue.waitUntilAllOperationsAreFinished()
    #endif

    XCTAssertEqual(resolvedServers.count, 100, "All instances should be different")
  }
  
  
  func testCircularReferenceThreadSafety() {
    container.register {
      ClientImp(server: try container.resolve()) as Client
    }
    
    container.register { ServerImp() as Server }
      .resolvingProperties { container, server in
        server.client = resolveClientSync()
    }
    
    for _ in 0..<100 {
      #if os(Linux)
      lock.lock()
      runningThreads += 1
      lock.unlock()

      dispatch_async { _ in
        resolveClientAsync()
        return nil
      }
      #else
      queue.addOperation(resolveClientAsync)
      #endif
    }
    
    #if os(Linux)
    while runningThreads > 0 { sleep(1) }
    #else
    queue.waitUntilAllOperationsAreFinished()
    #endif
    
    XCTAssertEqual(resolvedClients.count, 100, "Instances should be not reused in different object graphs")
    for client in resolvedClients {
      let service = client.server as! ServerImp
      let serviceClient = service.client as! ClientImp
      XCTAssertEqual(serviceClient, client, "Instances should be reused when resolving single object graph")
    }
  }
  
}


