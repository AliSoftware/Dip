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

private protocol Service: class {}
private class ServiceImp1: Service {}
private class ServiceImp2: Service {}

private class Server {
  weak var client: Client?
  
  init() {}
}

private class Client {
  var server: Server
  
  init(server: Server) {
    self.server = server
  }
}

class ComponentScopeTests: XCTestCase {
  
  let container = DependencyContainer()
  
  #if os(Linux)
  static var allTests: [(String, ComponentScopeTests -> () throws -> Void)] {
    return [
      ("testThatUniqueIsDefaultScope", testThatUniqueIsDefaultScope),
      ("testThatScopeCanBeChanged", testThatScopeCanBeChanged),
      ("testThatItResolvesTypeAsNewInstanceForUniqueScope", testThatItResolvesTypeAsNewInstanceForUniqueScope),
      ("testThatItReusesInstanceForSingletonScope", testThatItReusesInstanceForSingletonScope),
      ("testThatSingletonIsNotReusedAcrossContainers", testThatSingletonIsNotReusedAcrossContainers),
      ("testThatSingletonIsReleasedWhenDefinitionIsRemoved", testThatSingletonIsReleasedWhenDefinitionIsRemoved),
      ("testThatSingletonIsReleasedWhenDefinitionIsOverridden", testThatSingletonIsReleasedWhenDefinitionIsOverridden),
      ("testThatSingletonIsReleasedWhenContainerIsReset", testThatSingletonIsReleasedWhenContainerIsReset),
      ("testThatItReusesInstanceInSharedScopeDuringResolve", testThatItReusesInstanceInSharedScopeDuringResolve),
      ("testThatItDoesNotReuseInstanceInSharedScopeInNextResolve", testThatItDoesNotReuseInstanceInSharedScopeInNextResolve),
      ("testThatItDoesNotReuseInstanceInSharedScopeResolvedForNilTag", testThatItDoesNotReuseInstanceInSharedScopeResolvedForNilTagWhenResolvingForAnotherTag),
      ("testThatItReusesInstanceInSharedScopeResolvedForNilTag", testThatItReusesInstanceInSharedScopeResolvedForNilTag),
      ("testThatItReusesResolvedInstanceWhenResolvingOptional", testThatItReusesResolvedInstanceWhenResolvingOptional),
      ("testThatItHoldsWeakReferenceToWeakSingletonInstance",
          testThatItHoldsWeakReferenceToWeakSingletonInstance)
    ]
  }
  
  func setUp() {
    container.reset()
  }
  #else
  override func setUp() {
    container.reset()
  }
  #endif
  
  func testThatSharedIsDefaultScope() {
    let def = container.register { ServiceImp1() as Service }
    XCTAssertEqual(def.scope, ComponentScope.Shared)
  }
  
  func testThatScopeCanBeChanged() {
    let def = container.register(.Singleton) { ServiceImp1() as Service }
    XCTAssertEqual(def.scope, ComponentScope.Singleton)
  }
  
  func testThatItResolvesTypeAsNewInstanceForUniqueScope() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    let service1 = try! container.resolve() as Service
    let service2 = try! container.resolve() as Service
    
    //then
    XCTAssertFalse(service1 === service2)
  }
  
  func testThatItReusesInstanceForSingletonScope() {
    func test(scope: ComponentScope, line: UInt = #line) {
      //given
      container.register(scope) { ServiceImp1() as Service }
      
      //when
      let service1 = try! container.resolve() as Service
      let service2 = try! container.resolve() as Service
      
      //then
      XCTAssertTrue(service1 === service2, line: line)
    }
    
    test(.Singleton)
    test(.WeakSingleton)
    test(.EagerSingleton)
  }
  
  func testThatSingletonIsNotReusedAcrossContainers() {
    func test(scope: ComponentScope, line: UInt = #line) {
      //given
      let def = container.register(scope) { ServiceImp1() as Service }
      let secondContainer = DependencyContainer()
      secondContainer.register(def, forTag: nil)
      
      //when
      let service1 = try! container.resolve() as Service
      let service2 = try! secondContainer.resolve() as Service
      
      //then
      XCTAssertTrue(service1 !== service2, "Singleton instances should not be reused across containers", line: line)
    }
    
    test(.Singleton)
    test(.WeakSingleton)
    test(.EagerSingleton)
  }
  
  func testThatSingletonIsReleasedWhenDefinitionIsRemoved() {
    func test(scope: ComponentScope, line: UInt = #line) {
      //given
      let def = container.register(scope) { ServiceImp1() as Service }
      let service1 = try! container.resolve() as Service
      
      //when
      container.remove(def, forTag: nil)
      container.register(def, forTag: nil)
      
      //then
      let service2 = try! container.resolve() as Service
      XCTAssertTrue(service1 !== service2, "Singleton instances should be released when definition is removed from the container", line: line)
    }
    
    test(.Singleton)
    test(.WeakSingleton)
    test(.EagerSingleton)
  }
  
  func testThatSingletonIsReleasedWhenDefinitionIsOverridden() {
    func test(scope: ComponentScope, line: UInt = #line) {
      //given
      let def = container.register(scope) { ServiceImp1() as Service }
      let service1 = try! container.resolve() as Service
      
      //when
      container.register(def, forTag: nil)
      
      //then
      let service2 = try! container.resolve() as Service
      XCTAssertTrue(service1 !== service2, "Singleton instances should be released when definition is overridden", line: line)
    }
    
    test(.Singleton)
    test(.WeakSingleton)
    test(.EagerSingleton)
  }
  
  func testThatSingletonIsReleasedWhenContainerIsReset() {
    func test(scope: ComponentScope, line: UInt = #line) {
      //given
      let def = container.register(scope) { ServiceImp1() as Service }
      let service1 = try! container.resolve() as Service
      
      //when
      container.reset()
      container.register(def, forTag: nil)
      
      //then
      let service2 = try! container.resolve() as Service
      XCTAssertTrue(service1 !== service2, "Singleton instances should be released when container is reset", line: line)
    }
    
    test(.Singleton)
    test(.WeakSingleton)
    test(.EagerSingleton)
  }
  
  func testThatItReusesInstanceInSharedScopeDuringResolve() {
    //given
    container.register(.Shared) { Client(server: try self.container.resolve()) as Client }
    
    container.register(.Shared) { Server() as Server }
      .resolvingProperties { container, server in
        server.client = try container.resolve() as Client
    }
    
    //when
    let client = try! container.resolve() as Client
    
    //then
    let server = client.server
    XCTAssertTrue(server.client === client)
  }
  
  func testThatItDoesNotReuseInstanceInSharedScopeInNextResolve() {
    //given
    container.register(.Shared) { Client(server: try self.container.resolve()) as Client }
    container.register(.Shared) { Server() as Server }
      .resolvingProperties { container, server in
        server.client = try container.resolve() as Client
    }
    
    //when
    let client = try! container.resolve() as Client
    let server = client.server
    
    let anotherClient = try! container.resolve() as Client
    let anotherServer = anotherClient.server
    
    //then
    XCTAssertFalse(server === anotherServer)
    XCTAssertFalse(client === anotherClient)
  }

  func testThatItDoesNotReuseInstanceInSharedScopeResolvedForNilTagWhenResolvingForAnotherTag() {
    //given
    var service2: Service?
    container.register(.Shared) { ServiceImp1() as Service }
      .resolvingProperties { (c, _) in
        //when service1 is resolved using this definition due to fallback to nil tag
        service2 = try c.resolve(tag: "service") as Service
        
        //then we don't want every next resolve of service for other tags to reuse it
        XCTAssertTrue(service2 is ServiceImp2)
    }
    container.register(tag: "service", .Shared) { ServiceImp2() as Service}
    
    //when
    let service1 = try! container.resolve(tag: "tag") as Service

    //then
    XCTAssertTrue(service1 is ServiceImp1)
  }
  
  func testThatItReusesInstanceInSharedScopeResolvedForNilTag() {
    //given
    var service2: Service?
    container.register(.Shared) { ServiceImp1() as Service }
      .resolvingProperties { (c, service1) in
        guard service2 == nil else { return }
        
        //when service1 is resolved using this definition due to fallback to nil tag
        //and service is resolved again with another (existing) tag
        service2 = try c.resolve(tag: "tag") as Service
        
        //than we don't want every next resolve of service to reuse it
        XCTAssertTrue(service1 as! ServiceImp1 === service1)
    }
    
    //when
    let service1 = try! container.resolve(tag: "tag") as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
  }
  
  func testThatOnlyEagerSingletonIsCreatedWhenContainerIsBootsrapped() {
    //given
    var eagerSingletonResolved = false
    
    container.register(tag: "eager", .EagerSingleton) { ServiceImp1() as Service }
      .resolvingProperties { container, service in eagerSingletonResolved = true }
    
    container.register(tag: "singleton", .Singleton) { ServiceImp1() as Service }
      .resolvingProperties { container, service in XCTFail() }

    container.register(tag: "prototype", .Unique) { ServiceImp1() as Service }
      .resolvingProperties { container, service in XCTFail() }

    container.register(tag: "graph", .Shared) { ServiceImp1() as Service }
      .resolvingProperties { container, service in XCTFail() }
    
    //when
    try! container.bootstrap()
    XCTAssertTrue(eagerSingletonResolved)
  }
  
  func testThatContainerCanBeBootstrappedAgainAfterReset() {
    try! container.bootstrap()
    XCTAssertTrue(container.bootstrapped)
    
    container.reset()
    XCTAssertFalse(container.bootstrapped)
  }
  
  func testThatItReusesResolvedInstanceWhenResolvingOptional() {
    var otherService: Service!
    var impOtherService: Service!
    var anyOtherService: Any!
    var anyImpOtherService: Any!
    
    container.register(.Shared) { ServiceImp1() as Service }
      .resolvingProperties { container, service in
        otherService = try! container.resolve() as Service?
        impOtherService = try! container.resolve() as Service!
        anyOtherService = try! container.resolve((Service?).self)
        anyImpOtherService = try! container.resolve((Service!).self)
    }
    
    let service = try! container.resolve() as Service
    XCTAssertTrue(otherService as! ServiceImp1 === service as! ServiceImp1)
    XCTAssertTrue(impOtherService as! ServiceImp1 === service as! ServiceImp1)
    XCTAssertTrue(anyOtherService as! ServiceImp1 === service as! ServiceImp1)
    XCTAssertTrue(anyImpOtherService as! ServiceImp1 === service as! ServiceImp1)
  }
  
  func testThatItHoldsWeakReferenceToWeakSingletonInstance() {
    //given
    container.register(.WeakSingleton) { ServiceImp1() as Service }
    var strongSingleton: Service? = try! container.resolve() as Service
    weak var weakSingleton = try! container.resolve() as Service
    
    //then
    XCTAssertTrue(weakSingleton === strongSingleton)
    
    //when
    strongSingleton = nil
    
    //then
    XCTAssertNil(weakSingleton)
  }
  
  func testThatCollaboratingContainersReuseSingletonsResolvedByAnotherContainer() {
    func test(scope: ComponentScope, line: UInt = #line) {
      let container1 = DependencyContainer()
      container1.register(scope) { ServiceImp1() as Service }
      
      let container2 = DependencyContainer()
      container1.collaborate(with: container2)
      container2.collaborate(with: container1)
      
      try! container1.bootstrap()
      try! container2.bootstrap()
      
      let service1 = try! container1.resolve() as Service
      let service2 = try! container2.resolve() as Service
      
      XCTAssertTrue(service1 === service2, line: line, "\(scope) should be reused when first resolved from another container")
    }
    
    test(.Singleton)
    test(.WeakSingleton)
    test(.EagerSingleton)
  }
  
}

