//
//  RuntimeArgumentsTests.swift
//  DipTests
//
//  This code is under MIT Licence. See the LICENCE file for more info.
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
    
    var serverDefinition = container.register(.ObjectGraph) { Server() as Server }
    serverDefinition.resolveDependencies(container) { container, server in
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
    var serverDefinition = container.register(.ObjectGraph) { Server() as Server }
    serverDefinition.resolveDependencies(container) { container, server in
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
    var service1Definition = container.register(.ObjectGraph) { ServiceImp1() as Service }
    service1Definition.resolveDependencies(container) { (c, _) in
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
