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

class ComponentScopeTests: XCTestCase {
  
  let container = DependencyContainer()
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    container.reset()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testThatPrototypeIsDefaultScope() {
    let def = container.register { ServiceImp1() as Service }
    XCTAssertEqual(def.scope, ComponentScope.Prototype)
  }
  
  func testThatCallingInScopeChangesScope() {
    let def = container.register(ComponentScope.Singleton) { ServiceImp1() as Service }
    XCTAssertEqual(def.scope, ComponentScope.Singleton)
  }
  
  func testThatItResolvesTypeAsNewInstanceForPrototypeScope() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    let service1 = container.resolve() as Service
    let service2 = container.resolve() as Service
    
    //then
    XCTAssertFalse((service1 as! ServiceImp1) === (service2 as! ServiceImp1))
  }
  
  func testThatItReusesInstanceForSingletonScope() {
    //given
    container.register(.Singleton) { ServiceImp1() as Service }
    
    //when
    let service1 = container.resolve() as Service
    let service2 = container.resolve() as Service
    
    //then
    XCTAssertTrue((service1 as! ServiceImp1) === (service2 as! ServiceImp1))
  }
  
  class Server {
    weak var client: Client?
    
    init() {}
  }
  
  class Client {
    var server: Server
    
    init(server: Server) {
      self.server = server
    }
  }

  func testThatItReusesInstanceInObjectGraphScopeDuringResolve() {
    //given
    container.register(.ObjectGraph) { [unowned container] in Client(server: container.resolve()) as Client }
    
    container.register(.ObjectGraph) { Server() as Server }.resolveDependencies { container, server in
      server.client = container.resolve() as Client
    }
    
    //when
    let client = container.resolve() as Client
    
    //then
    let server = client.server
    XCTAssertTrue(server.client === client)
  }
  
  func testThatItDoesNotReuseInstanceInObjectGraphScopeInNextResolve() {
    //given
    container.register(.ObjectGraph) { [unowned container] in Client(server: container.resolve()) as Client }
    container.register(.ObjectGraph) { Server() as Server }.resolveDependencies { container, server in
      server.client = container.resolve() as Client
    }
    
    //when
    let client = container.resolve() as Client
    let server = client.server
    
    let anotherClient = container.resolve() as Client
    let anotherServer = anotherClient.server
    
    //then
    XCTAssertFalse(server === anotherServer)
    XCTAssertFalse(client === anotherClient)
  }

  func testThatItDoesNotReuseInstanceInObjectGraphScopeResolvedForNilTag() {
    //given
    var service2: Service?
    container.register(.ObjectGraph) { ServiceImp1() as Service }.resolveDependencies { (c, _) in
      service2 = c.resolve(tag: "service") as Service
    }
    container.register(tag: "service", .ObjectGraph) { ServiceImp2() as Service}
    
    //when
    let service1 = container.resolve(tag: "tag") as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
    XCTAssertTrue(service2 is ServiceImp2)
  }

}
