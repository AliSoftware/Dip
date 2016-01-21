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
  weak var client: Client? {get}
  
  var anotherClient: Client? {get set}
}

private protocol Client: class {
  var server: Server? {get}
  var anotherServer: Server? {get set}
}

class AutoInjectionTests: XCTestCase {
  
  static var serverDeallocated: Bool = false
  static var clientDeallocated: Bool = false

  private class ServerImp: Server {
    
    deinit {
      AutoInjectionTests.serverDeallocated = true
    }
    
    var _client = InjectedWeak<Client>()
    
    weak var client: Client? {
      return _client.value
    }
    
    weak var anotherClient: Client?
  }
  
  private class ClientImp: Client {
    
    deinit {
      AutoInjectionTests.clientDeallocated = true
    }
    
    var _server = Injected<Server>()
    var anotherServer: Server?
    
    var server: Server? {
      return _server.value
    }
    
  }

  let container = DependencyContainer()
  
  override func setUp() {
    super.setUp()

    container.reset()
    AutoInjectionTests.serverDeallocated = false
    AutoInjectionTests.clientDeallocated = false
    
    container.register(.ObjectGraph) { ServerImp() as Server }
    container.register(.ObjectGraph) { ClientImp() as Client }
  }

  func testThatItResolvesInjectedDependencies() {
    let client = try! container.resolve() as Client
    let server = client.server
    XCTAssertTrue(client as! ClientImp === server?.client as! ClientImp)
  }
  
  func testThatThereIsNoRetainCycleForCyrcularDependencies() {
    //given
    var client: Client? = try! container.resolve() as Client
    XCTAssertNotNil(client)
    
    //when
    client = nil
    
    //then
    XCTAssertTrue(AutoInjectionTests.clientDeallocated)
    XCTAssertTrue(AutoInjectionTests.serverDeallocated)
  }
  
  func testThatItResolvesAutoInjectedSingletons() {
    container.reset()
    
    //given
    container.register(.Singleton) { ServerImp() as Server }
    container.register(.Singleton) { ClientImp() as Client }
    
    //when
    let sharedClient = try! container.resolve() as Client
    let sharedServer = try! container.resolve() as Server

    let client = try! container.resolve() as Client
    let server = client.server
    
    //then
    XCTAssertTrue(client as! ClientImp === sharedClient as! ClientImp)
    XCTAssertTrue(client as! ClientImp === server?.client as! ClientImp)
    XCTAssertTrue(server as! ServerImp === sharedServer as! ServerImp)
  }
  
  func testThatItCallsResolveDependencyBlockOnOriginalDefiniton() {
    var serverBlockWasCalled = false
    container.register(.ObjectGraph) { ServerImp() as Server }
      .resolveDependencies { (container, server) -> () in
        serverBlockWasCalled = true
    }


    try! container.resolve() as Client
    XCTAssertTrue(serverBlockWasCalled)

    var clientBlockWasCalled = false
    container.register(.ObjectGraph) { ClientImp() as Client }
      .resolveDependencies { (container, client) -> () in
        clientBlockWasCalled = true
    }
    try! container.resolve() as Server

    XCTAssertTrue(clientBlockWasCalled)
  }
  
  func testThatItReuseResolvedAutoInjectedInstences() {
    
    container.register(.ObjectGraph) { ServerImp() as Server }
      .resolveDependencies { (container, server) -> () in
        server.anotherClient = try! container.resolve() as Client
    }

    container.register(.ObjectGraph) { ClientImp() as Client }
      .resolveDependencies { (container, client) -> () in
        client.anotherServer = try! container.resolve() as Server
    }

    let client = (try! container.resolve() as Client) as! ClientImp
    
    let server = client.server as! ServerImp
    let anotherServer = client.anotherServer as! ServerImp
    
    XCTAssertTrue(server === anotherServer)
    
    let oneClient = server.client as! ClientImp
    let anotherClient = server.anotherClient as! ClientImp
    
    XCTAssertTrue(oneClient === anotherClient)
    XCTAssertTrue(client === anotherClient)
  }
  
  func testThatItReuseResolvedAutoInjectedInstancesNoMatterWhat() {
    
    class Obj1 {
      let obj2 = InjectedWeak<Obj2>()
      let obj3 = Injected<Obj3>()
    }
    
    class Obj2 {
      let obj1 = Injected<Obj1>()
    }
    
    class Obj3 {
      
      weak var obj1: Obj1?
      
      init(obj: Obj1) {
        self.obj1 = obj
      }
    }
    
    container.register(.ObjectGraph) { Obj1() }
    container.register(.ObjectGraph) { Obj2() }
    container.register(.ObjectGraph) { Obj3(obj: try self.container.resolve()) }
    
    let obj2 = try! container.resolve() as Obj2
    XCTAssertTrue(obj2 === obj2.obj1.value!.obj2.value!)
    XCTAssertTrue(obj2.obj1.value! === obj2.obj1.value!.obj3.value!.obj1)
    
  }
  
  func testThatThereIsNoRetainCycleBetweenCircularDependencies() {
    var client: Client? = try! container.resolve() as Client
    weak var server: Server? = client?.server

    weak var weakClient = client
    
    XCTAssertNotNil(weakClient)
    XCTAssertNotNil(server)
    
    client = nil

    XCTAssertNil(weakClient)
    XCTAssertNil(server)

  }
}
