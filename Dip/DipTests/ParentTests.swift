//
//  ParentTests.swift
//  Dip
//
//  Created by John Twigg on 7/28/17.
//  Copyright © 2017 AliSoftware. All rights reserved.
//

import XCTest
@testable import Dip

protocol Servicable {}

class ParentTests: XCTestCase {
    
  override func setUp() {
      super.setUp()
      // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()
  }


  class ServiceA {}

  class Password {
    let text: String
    let service : ServiceA

    init(text:String, service: ServiceA) {
      self.text = text
      self.service = service
    }
  }


  /**
    Child containers should not have access to each others registries
    Root containers don't have access to their childrens registries either
   */
  func testChildContainersAreIsolatedFromEachOther() {

    let rootContainer = DependencyContainer()

    var countR = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      countR = countR + 1
      return ServiceA()
    }

    XCTAssertNotNil(try? rootContainer.resolve() as ServiceA)

    let userA = DependencyContainer(parent: rootContainer)
    var countA = 0
    userA.register(.singleton) { (serviceA: ServiceA) -> Password in
      countA = countA + 1
      return Password(text: "1234", service:serviceA)
    }


    let userB = DependencyContainer(parent: rootContainer)
    var countB = 0
    userB.register(.singleton) { (serviceA: ServiceA) -> Password in
      countB = countB + 1
      return Password(text: "ABCD", service:serviceA)
    }

    XCTAssert((try! userA.resolve() as Password).text == "1234")
    XCTAssert(countR == 1)
    XCTAssert(countA == 1)


    XCTAssert((try! userB.resolve() as Password).text == "ABCD")
    XCTAssert(countR == 1)
    XCTAssert(countB == 1)

    //Root doesn't have access to its children.
    XCTAssertNil(try? rootContainer.resolve() as Password)
  }


  /**
    Child containers should not have access to each others registries
    neven when they will fail to resolve
   */
  func testChildContainersDontFailOver() {

    let rootContainer = DependencyContainer()

    var count = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      count = count + 1
      return ServiceA()
    }

    //Logged in user.
    let loggedIn = DependencyContainer(parent: rootContainer)
    loggedIn.register(.singleton) { Password(text: "1234", service:$0) }
    let passwordLoggedIn : Password? = try? loggedIn.resolve() as Password
    XCTAssert(passwordLoggedIn?.text == "1234")
    XCTAssert(count == 1)


    //UnLogged in user doesn't have access to Logged in users data.
    let unloggedIn = DependencyContainer(parent: rootContainer)
    let passwordUnloggedIn = try? unloggedIn.resolve() as Password
    XCTAssertNil(passwordUnloggedIn);
    XCTAssert(count == 1)

    //Root container doesn't have access to child containers data.
    XCTAssertNil(try? rootContainer.resolve() as Password)
  }


  class RootTransientDep { }
  class ChildTransientDep {}

  class ChildAggregate {
    let rootDep : RootTransientDep
    var anotherRootDep : RootTransientDep?

    let childDep : ChildTransientDep
    var anotherChildDep : ChildTransientDep?


    init(rootDep : RootTransientDep, childDep : ChildTransientDep){
      self.rootDep = rootDep
      self.childDep = childDep
    }
  }

/**
  Instances of that are resolved from parents are reused during
  the same call resolve context.
 */
  func testParentContainersReuseInstances() {
    let rootContainer = DependencyContainer()

    var countR = 0
    rootContainer.register { () -> RootTransientDep in
      countR = countR + 1
      return RootTransientDep()
    }

    let childContainer = DependencyContainer(parent: rootContainer)
    childContainer.register {
      ChildAggregate(rootDep: $0, childDep: $1)
      }.resolvingProperties { (container, childAggregate) -> () in
        childAggregate.anotherRootDep = try? container.resolve()
        childAggregate.anotherChildDep = try? container.resolve()
    }

    var countC = 0
    childContainer.register { () -> ChildTransientDep in
      countC = countC + 1
      return ChildTransientDep()
    }

    let childAggregate: ChildAggregate? = try? childContainer.resolve() as ChildAggregate

    XCTAssertNotNil(childAggregate)
    XCTAssert(countR == 1)
    XCTAssert(countC == 1)

    XCTAssert(childAggregate?.rootDep === childAggregate?.anotherRootDep)
    XCTAssert(childAggregate?.childDep === childAggregate?.anotherChildDep)

  }


  class LevelOne {
    let title: String
    init(title: String) {
      self.title = title
    }

  }

  class LevelTwo {
    let levelOne : LevelOne
    init(levelOne : LevelOne ){
      self.levelOne = levelOne
    }
  }

  class LevelThree {
    let levelTwo : LevelTwo
    var anotherLevelTwo : LevelTwo?
    init(levelTwo : LevelTwo ){
      self.levelTwo = levelTwo
    }
  }


  func testTwoParentInHierachyStillReusesInstances() {

    let levelOneContainer = DependencyContainer()
    levelOneContainer.register {
      LevelOne(title: "OccuresInLevelOne")
    }

    let levelTwoContainer = DependencyContainer(parent: levelOneContainer)
    levelTwoContainer.register {
      LevelTwo(levelOne: $0)
    }

    let levelThreeContainer = DependencyContainer(parent: levelTwoContainer)
    levelThreeContainer.register {
      LevelThree(levelTwo: $0)
      }.resolvingProperties { (container, levelThreeContainer) -> () in
        levelThreeContainer.anotherLevelTwo = try? container.resolve() as LevelTwo
    }


    guard let levelThree = try? levelThreeContainer.resolve() as LevelThree else {
      XCTFail("Nil returned from level three resolve")
      return
    }

    XCTAssertNotNil(levelThree.anotherLevelTwo)
    XCTAssert(levelThree.levelTwo === levelThree.anotherLevelTwo)
    XCTAssert(levelThree.levelTwo.levelOne === levelThree.anotherLevelTwo?.levelOne, "The levelOne object should have been reused")
    XCTAssert(levelThree.levelTwo.levelOne.title == "OccuresInLevelOne")
  }

  class LevelThreeAggregate {
    let levelThree : LevelThree
    let levelOne : LevelOne

    init(levelThree: LevelThree, levelOne : LevelOne)
    {
      self.levelThree = levelThree
      self.levelOne = levelOne
    }
  }

  /**
     Resolving Containers that are overriden by a child, should use the childs implementation,
     even when the the autoresolve occurs from a parent container
   */
  func testOverridingInChildContainerIsCapturedandReused() {

    let levelOneContainer = DependencyContainer()
    levelOneContainer.register { () -> LevelOne in
      XCTFail("Should not retrieve")
      return LevelOne(title:"OccursInLevelOne")
    }

    let levelTwoContainer = DependencyContainer(parent: levelOneContainer)
    levelTwoContainer.register {
      LevelTwo(levelOne: $0)
    }

    let levelThreeContainer = DependencyContainer(parent: levelTwoContainer)
    levelThreeContainer.register {
      LevelThree(levelTwo: $0)
      }.resolvingProperties { (container, levelThreeContainer) -> () in
        levelThreeContainer.anotherLevelTwo = try? container.resolve() as LevelTwo
    }
    levelThreeContainer.register {
      LevelOne(title:"OccuresInLevelThree")
    }

    levelThreeContainer.register {
      LevelThreeAggregate(levelThree: $0, levelOne: $1)
    }

    guard let levelThreeAggregate = try? levelThreeContainer.resolve() as LevelThreeAggregate else {
      XCTFail("Nil returned from level three aggregate resolve")
      return
    }

    XCTAssert(levelThreeAggregate.levelOne === levelThreeAggregate.levelThree.levelTwo.levelOne)
    XCTAssert(levelThreeAggregate.levelOne.title == "OccuresInLevelThree")
  }

  class LevelThreeInjected {
    let levelThree : LevelThree
    let levelOne = Injected<LevelOne>()

    init(levelThree: LevelThree) {
      self.levelThree = levelThree
    }
  }



  /**
   Injected properties are captured and overridden by child classes when appropriate.
   */
  func testOverridingInjectionProperties() {
    let levelOneContainer = DependencyContainer()
    levelOneContainer.register { () -> LevelOne in
      XCTFail("Should not retrieve")
      return LevelOne(title:"OccuresInLevelOne")
    }

    let levelTwoContainer = DependencyContainer(parent: levelOneContainer)
    levelTwoContainer.register {
      LevelTwo(levelOne: $0)
    }

    let levelThreeContainer = DependencyContainer(parent: levelTwoContainer)
    levelThreeContainer.register {
      LevelThree(levelTwo: $0)
      }.resolvingProperties { (container, levelThreeContainer) -> () in
        levelThreeContainer.anotherLevelTwo = try? container.resolve() as LevelTwo
    }
    levelThreeContainer.register {
      LevelOne(title:"OccuresInLevelThree")
    }

    levelThreeContainer.register {
      LevelThreeInjected(levelThree: $0)
    }

    guard let levelThreeInjected = try? levelThreeContainer.resolve() as LevelThreeInjected else {
      XCTFail("Nil returned from level three aggregate resolve")
      return
    }

    XCTAssert(levelThreeInjected.levelOne.value?.title  == "OccuresInLevelThree")
    XCTAssert(levelThreeInjected.levelThree.levelTwo.levelOne === levelThreeInjected.levelOne.value)
  }


  class DependancyA : Servicable{}
  class DependancyB : Servicable{}

  class ConcreteA {
    let servicable = Injected<Servicable>()
  }

  class ConcreteB {
    let servicable : Servicable

    init(servicable : Servicable) {
      self.servicable = servicable
    }
  }


  /**
   Protocol forwarding can be  overriden by children.
   */
  func testOverridingProtocolForwardingIsCapturedCorrectly() {

    let rootContainer = DependencyContainer()
    rootContainer.register { () -> DependancyA in
      DependancyA()
    }.implements(Servicable.self)

    rootContainer.register { () -> ConcreteA in
      ConcreteA()
    }

    let childContainer = DependencyContainer(parent: rootContainer)

    childContainer.register { () -> DependancyB in
      DependancyB()
    }.implements(Servicable.self)

    childContainer.register(factory: ConcreteB.init)

    //Test Child
    //Resolving with the child should always use overridden values.
    var concreteA: ConcreteA? = try? childContainer.resolve()
    XCTAssertNotNil(concreteA)
    XCTAssertNotNil(concreteA?.servicable.value as? DependancyB)

    let concreteB: ConcreteB? = try? childContainer.resolve()
    XCTAssertNotNil(concreteB)
    XCTAssertNotNil(concreteB?.servicable as? DependancyB) //Overridden


    //Test Rpot
    //REsolving directly to the root should only access classes its registered with.
    concreteA = try? rootContainer.resolve()
    XCTAssertNotNil(concreteA)
    XCTAssertNotNil(concreteA?.servicable.value as? DependancyA)//Note: root still references DependancyA

    //Root container should not have access to dependancies registered in children
    XCTAssertNil(try? rootContainer.resolve())
    XCTAssertNil(try? rootContainer.resolve() as DependancyB)


    XCTAssertNoThrow(try childContainer.validate())
  }

}
