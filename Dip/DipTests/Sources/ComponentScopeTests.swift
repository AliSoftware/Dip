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
  var allTests: [(String, () throws -> Void)] {
    return [
      ("testThatPrototypeIsDefaultScope", testThatPrototypeIsDefaultScope),
      ("testThatScopeCanBeChanged", testThatScopeCanBeChanged),
      ("testThatItResolvesTypeAsNewInstanceForPrototypeScope", testThatItResolvesTypeAsNewInstanceForPrototypeScope),
      ("testThatItReusesInstanceForSingletonScope", testThatItReusesInstanceForSingletonScope),
      ("testThatSingletonIsNotReusedAcrossContainers", testThatSingletonIsNotReusedAcrossContainers),
      ("testThatSingletonIsReleasedWhenDefinitionIsRemoved", testThatSingletonIsReleasedWhenDefinitionIsRemoved),
      ("testThatSingletonIsReleasedWhenDefinitionIsOverridden", testThatSingletonIsReleasedWhenDefinitionIsOverridden),
      ("testThatSingletonIsReleasedWhenContainerIsReset", testThatSingletonIsReleasedWhenContainerIsReset),
      ("testThatItReusesInstanceInObjectGraphScopeDuringResolve", testThatItReusesInstanceInObjectGraphScopeDuringResolve),
      ("testThatItDoesNotReuseInstanceInObjectGraphScopeInNextResolve", testThatItDoesNotReuseInstanceInObjectGraphScopeInNextResolve),
      ("testThatItDoesNotReuseInstanceInObjectGraphScopeResolvedForNilTag", testThatItDoesNotReuseInstanceInObjectGraphScopeResolvedForNilTag)
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
  
  func testThatPrototypeIsDefaultScope() {
    let def = container.register { ServiceImp1() as Service }
    XCTAssertEqual(def.scope, ComponentScope.Prototype)
  }
  
  func testThatScopeCanBeChanged() {
    let def = container.register(.Singleton) { ServiceImp1() as Service }
    XCTAssertEqual(def.scope, ComponentScope.Singleton)
  }
  
  func testThatItResolvesTypeAsNewInstanceForPrototypeScope() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    let service1 = try! container.resolve() as Service
    let service2 = try! container.resolve() as Service
    
    //then
    XCTAssertFalse(service1 === service2)
  }
  
  func testThatItReusesInstanceForSingletonScope() {
    //given
    container.register(.Singleton) { ServiceImp1() as Service }
    
    //when
    let service1 = try! container.resolve() as Service
    let service2 = try! container.resolve() as Service
    
    //then
    XCTAssertTrue(service1 === service2)
  }
  
  func testThatSingletonIsNotReusedAcrossContainers() {
    //given
    let def = container.register(.Singleton) { ServiceImp1() as Service }
    let secondContainer = DependencyContainer()
    secondContainer.register(def, forTag: nil)
    
    //when
    let service1 = try! container.resolve() as Service
    let service2 = try! secondContainer.resolve() as Service
    
    //then
    XCTAssertTrue(service1 !== service2, "Singleton instances should not be reused across containers")
  }
  
  func testThatSingletonIsReleasedWhenDefinitionIsRemoved() {
    //given
    let def = container.register(.Singleton) { ServiceImp1() as Service }
    let service1 = try! container.resolve() as Service
    
    //when
    container.remove(def, forTag: nil)
    container.register(def, forTag: nil)
    
    //then
    let service2 = try! container.resolve() as Service
    XCTAssertTrue(service1 !== service2, "Singleton instances should be released when definition is removed from the container")
  }
  
  func testThatSingletonIsReleasedWhenDefinitionIsOverridden() {
    //given
    let def = container.register(.Singleton) { ServiceImp1() as Service }
    let service1 = try! container.resolve() as Service
    
    //when
    container.register(def, forTag: nil)
    
    //then
    let service2 = try! container.resolve() as Service
    XCTAssertTrue(service1 !== service2, "Singleton instances should be released when definition is overridden")
  }
  
  func testThatSingletonIsReleasedWhenContainerIsReset() {
    //given
    let def = container.register(.Singleton) { ServiceImp1() as Service }
    let service1 = try! container.resolve() as Service
    
    //when
    container.reset()
    container.register(def, forTag: nil)
    
    //then
    let service2 = try! container.resolve() as Service
    XCTAssertTrue(service1 !== service2, "Singleton instances should be released when container is reset")
  }
  
  func testThatItReusesInstanceInObjectGraphScopeDuringResolve() {
    //given
    container.register(.ObjectGraph) { Client(server: try self.container.resolve()) as Client }
    
    container.register(.ObjectGraph) { Server() as Server }.resolveDependencies { container, server in
      server.client = try container.resolve() as Client
    }
    
    //when
    let client = try! container.resolve() as Client
    
    //then
    let server = client.server
    XCTAssertTrue(server.client === client)
  }
  
  func testThatItDoesNotReuseInstanceInObjectGraphScopeInNextResolve() {
    //given
    container.register(.ObjectGraph) { Client(server: try self.container.resolve()) as Client }
    container.register(.ObjectGraph) { Server() as Server }.resolveDependencies { container, server in
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

  func testThatItDoesNotReuseInstanceInObjectGraphScopeResolvedForNilTag() {
    //given
    var service2: Service?
    container.register(.ObjectGraph) { ServiceImp1() as Service }.resolveDependencies { (c, _) in
      service2 = try c.resolve(tag: "service") as Service
      
      //then

      //when service1 is resolved using this definition due to fallback to nil tag
      //we don't want every next resolve of service reuse it
      XCTAssertTrue(service2 is ServiceImp2)
    }
    container.register(tag: "service", .ObjectGraph) { ServiceImp2() as Service}
    
    //when
    let service1 = try! container.resolve(tag: "tag") as Service

    //then
    XCTAssertTrue(service1 is ServiceImp1)
  }

}

