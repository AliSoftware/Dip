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

#if canImport(ObjectiveC)
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
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

private func ==<T: ServerImp>(lhs: T, rhs: T) -> Bool {
  return lhs === rhs
}

private var resolvedServers = Set<ServerImp>()
private var resolvedClients = Array<ClientImp>()

private var container: DependencyContainer!

let queue = OperationQueue()
let lock = RecursiveLock()
  
private let resolveClientSync: () -> Client? = {
  var client: Client?
  DispatchQueue.global(qos: .default).sync() {
    client = try! container.resolve() as Client
  }
  return client
}

let resolveServerAsync = {
  let server = try! container.resolve() as Server
  lock.lock()
  resolvedServers.insert(server as! ServerImp)
  lock.unlock()
}

let resolveClientAsync = {
  let client = try! container.resolve() as Client
  lock.lock()
  resolvedClients.append(client as! ClientImp)
  lock.unlock()
}

class ThreadSafetyTests: XCTestCase {
  
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
      queue.addOperation(resolveServerAsync)
    }
    
    queue.waitUntilAllOperationsAreFinished()
    
    XCTAssertEqual(resolvedServers.count, 1, "Should create only one instance")
  }
  
  
  func testFactoryThreadSafety() {
    container.register { ServerImp() as Server }
    
    for _ in 0..<100 {
      queue.addOperation(resolveServerAsync)
    }
    
    queue.waitUntilAllOperationsAreFinished()

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
      queue.addOperation(resolveClientAsync)
    }
    
    queue.waitUntilAllOperationsAreFinished()
    
    XCTAssertEqual(resolvedClients.count, 100, "Instances should be not reused in different object graphs")
    for client in resolvedClients {
      let service = client.server as! ServerImp
      let serviceClient = service.client as! ClientImp
      XCTAssertEqual(serviceClient, client, "Instances should be reused when resolving single object graph")
    }
  }
  
}
#endif
