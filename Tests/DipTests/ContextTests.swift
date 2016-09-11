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

private protocol Service {}
private class ServiceImp1: Service {
  let injected = Injected<ServiceImp2>()
  let injectedWeak = InjectedWeak<ServiceImp2>()
  let taggedInjected = Injected<ServiceImp2>(tag: "injectedTag")
  let taggedInjectedWeak = InjectedWeak<ServiceImp2>(tag: "injectedTag")
  let injectedNilTag = Injected<ServiceImp2>(tag: nil)
}
private class ServiceImp2: Service {}

class ContextTests: XCTestCase {

  let container = DependencyContainer()
  
  static var allTests = {
    return [
      ("testThatContextStoresCurrentlyResolvedType", testThatContextStoresCurrentlyResolvedType),
      ("testThatContextStoresInjectedInType", testThatContextStoresInjectedInType),
      ("testThatContextStoresTheTagPassedToResolve", testThatContextStoresTheTagPassedToResolve),
      ("testThatContextStoresTheTagPassedToResolveWhenAutoInjecting", testThatContextStoresTheTagPassedToResolveWhenAutoInjecting),
      ("testThatContextStoresTheTagPassedToResolveWhenAutoWiring", testThatContextStoresTheTagPassedToResolveWhenAutoWiring),
      ("testThatContextDoesNotOverrideNilTagPassedToResolve", testThatContextDoesNotOverrideNilTagPassedToResolve),
      ("testThatContextStoresNameOfAutoInjectedProperty", testThatContextStoresNameOfAutoInjectedProperty),
      ("testThatItDoesNotSetInjectedInTypeWhenResolvingWithCollaboration", testThatItDoesNotSetInjectedInTypeWhenResolvingWithCollaboration),
      ("testThatContextIsPreservedWhenResolvingWithCollaboration", testThatContextIsPreservedWhenResolvingWithCollaboration)
    ]
  }()
  
  override func setUp() {
    container.reset()
    container.register { ServiceImp2() }
  }

  func testThatContextStoresCurrentlyResolvedType() {
    container.register { () -> Service in
      XCTAssertTrue(self.container.context.resolvingType == Service.self)
      let _ = try self.container.resolve() as ServiceImp1
      return ServiceImp1() as Service
      }.resolvingProperties { _ in
        XCTAssertTrue(self.container.context.resolvingType == Service.self)
        let _ = try self.container.resolve() as ServiceImp1
    }
    
    container.register { () -> ServiceImp1 in
      XCTAssertTrue(self.container.context.resolvingType == ServiceImp1.self)
      return ServiceImp1()
      }.resolvingProperties { _ in
        XCTAssertTrue(self.container.context.resolvingType == ServiceImp1.self)
    }
    
    let _ = try! container.resolve() as Service
  }
  
  func testThatContextStoresInjectedInType() {
    container.register { () -> Service in
      XCTAssertNil(self.container.context.injectedInType)
      let _ = try self.container.resolve() as ServiceImp1
      return ServiceImp1() as Service
      }.resolvingProperties { _ in
        XCTAssertNil(self.container.context.injectedInType)
        let _ = try self.container.resolve() as ServiceImp1
    }
    
    container.register { () -> ServiceImp1 in
      XCTAssertTrue(self.container.context.injectedInType == Service.self)
      return ServiceImp1()
      }.resolvingProperties { _ in
        XCTAssertTrue(self.container.context.injectedInType == Service.self)
    }
    
    let _ = try! container.resolve() as Service
  }

  func testThatContextStoresTheTagPassedToResolve() {
    container.register { () -> Service in
      XCTAssertNotNil(self.container.context.tag)
      XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
      let _ = try self.container.resolve(tag: "otherTag") as ServiceImp1
      return ServiceImp1() as Service
      }.resolvingProperties { _ in
        XCTAssertNotNil(self.container.context.tag)
        XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
        let _ = try self.container.resolve(tag: "otherTag") as ServiceImp1
    }
    
    container.register { () -> ServiceImp1 in
      XCTAssertNotNil(self.container.context.tag)
      XCTAssertTrue(DependencyContainer.Tag.String("otherTag") ~= self.container.context.tag!)
      return ServiceImp1()
      }.resolvingProperties { _ in
        XCTAssertNotNil(self.container.context.tag)
        XCTAssertTrue(DependencyContainer.Tag.String("otherTag") ~= self.container.context.tag!)
    }
    
    let _ = try! container.resolve(tag: "tag") as Service
  }
  
  func testThatContextStoresTheTagPassedToResolveWhenAutoInjecting() {
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp1() }
    
    container.register { () -> ServiceImp2 in
      if self.container.context.injectedInProperty == "injectedNilTag" {
        XCTAssertNil(self.container.context.tag)
      }
      else {
        XCTAssertNotNil(self.container.context.tag)
        XCTAssertTrue(DependencyContainer.Tag.String("injectedTag") ~= self.container.context.tag!)
      }
      return ServiceImp2()
      }.resolvingProperties { _ in
        if self.container.context.injectedInProperty == "injectedNilTag" {
          XCTAssertNil(self.container.context.tag)
        }
        else {
          XCTAssertNotNil(self.container.context.tag)
          XCTAssertTrue(DependencyContainer.Tag.String("injectedTag") ~= self.container.context.tag!)
        }
    }
    
    container.register(tag: "tag") { () -> ServiceImp2 in
      XCTAssertNotNil(self.container.context.tag)
      XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
      return ServiceImp2()
      }.resolvingProperties { _ in
        XCTAssertNotNil(self.container.context.tag)
        XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
    }
    
    let _ = try! container.resolve(tag: "tag") as Service
  }

  func testThatContextStoresTheTagPassedToResolveWhenAutoWiring() {
    container.register { (_: ServiceImp1) -> Service in
      return ServiceImp1() as Service
      }.resolvingProperties { _ in
    }
    
    container.register { () -> ServiceImp1 in
      XCTAssertNotNil(self.container.context.tag)
      XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
      return ServiceImp1()
      }.resolvingProperties { _ in
        XCTAssertNotNil(self.container.context.tag)
        XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
    }
    
    let _ = try! container.resolve(tag: "tag") as Service
  }

  func testThatContextDoesNotOverrideNilTagPassedToResolve() {
    container.register { () -> Service in
      XCTAssertNotNil(self.container.context.tag)
      XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
      let _ = try self.container.resolve() as ServiceImp1
      return ServiceImp1() as Service
      }.resolvingProperties { _ in
        XCTAssertNotNil(self.container.context.tag)
        XCTAssertTrue(DependencyContainer.Tag.String("tag") ~= self.container.context.tag!)
        let _ = try self.container.resolve() as ServiceImp1
    }
    
    container.register { () -> ServiceImp1 in
      XCTAssertNil(self.container.context.tag)
      return ServiceImp1()
      }.resolvingProperties { _ in
        XCTAssertNil(self.container.context.tag)
    }
    
    let _ = try! container.resolve(tag: "tag") as Service
  }
  
  func testThatContextStoresNameOfAutoInjectedProperty() {
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp1() }
    
    let names = ["injected", "injectedWeak", "taggedInjected", "taggedInjectedWeak", "injectedNilTag"]
    
    container.register { () -> ServiceImp2 in
      XCTAssertNotNil(self.container.context.injectedInProperty)
      XCTAssertTrue(names.contains(self.container.context.injectedInProperty!))
      return ServiceImp2()
      }.resolvingProperties { _ in
        XCTAssertNotNil(self.container.context.injectedInProperty)
        XCTAssertTrue(names.contains(self.container.context.injectedInProperty!))
    }
    
    let _ = try! container.resolve() as Service
  }
  
  func testThatItDoesNotSetInjectedInTypeWhenResolvingWithCollaboration() {
    let collaborator = DependencyContainer()
    
    collaborator.register { () -> ServiceImp1 in
      unowned let collaborator = collaborator
      XCTAssertNil(collaborator.context.injectedInType)
      return ServiceImp1()
      }.resolvingProperties { collaborator, _ in
        XCTAssertNil(collaborator.context.injectedInType)
    }
    
    container.collaborate(with: collaborator)
    collaborator.collaborate(with: container)
    
    let _ = try! container.resolve() as ServiceImp1
  }
  
  func testThatContextIsPreservedWhenResolvingWithCollaboration() {
    let collaborator = DependencyContainer()
    
    container.register { () -> Service in
      XCTAssertTrue(self.container.context.resolvingType == Service.self)
      let _ = try self.container.resolve() as ServiceImp1
      return ServiceImp1() as Service
      }.resolvingProperties { _ in
        XCTAssertTrue(self.container.context.resolvingType == Service.self)
        let _ = try self.container.resolve() as ServiceImp1
    }
    
    collaborator.register { () -> ServiceImp1 in
      XCTAssertTrue(collaborator.context.resolvingType == ServiceImp1.self)
      return ServiceImp1()
      }.resolvingProperties { _ in
        XCTAssertTrue(collaborator.context.resolvingType == ServiceImp1.self)
    }
    
    container.collaborate(with: collaborator)
    collaborator.collaborate(with: container)
    let _ = try! container.resolve() as Service

    collaborator.reset()
  }
  
}
