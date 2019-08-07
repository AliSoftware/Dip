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

  class LevelTwo : Resolvable{
    let levelOne : LevelOne
    var resolvedInjectedContainer : DependencyContainer?
    var resolveCount = 0

    init(levelOne : LevelOne ){
      self.levelOne = levelOne
    }

    func resolveDependencies(_ container: DependencyContainer){
      resolveCount = resolveCount + 1
      resolvedInjectedContainer = container
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
    }.resolvingProperties { (container, levelTwo) -> () in
      let levelOne = try container.resolve() as LevelOne
      XCTAssert(levelOne === levelTwo.levelOne)
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

  class DependancyX{}

  class DependancyWithInputA : Servicable{
    init(x: DependancyX) {}
  }
  class DependancyWithInputB : Servicable{
    init(x: DependancyX) {}
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

  func testOverridingImplementationWorks() {
    let rootContainer = DependencyContainer()
    var exectued = false
    rootContainer.register { (x: DependancyX) -> DependancyWithInputA in
      XCTFail()
      exectued = true
      return DependancyWithInputA(x:x)
    }.implements(Servicable.self)

    rootContainer.register { () -> DependancyX in
      DependancyX()
    }
    rootContainer.register { () -> ConcreteA in
      ConcreteA()
    }

    rootContainer.register {
        LevelThreeAggregate(levelThree: $0, levelOne: $1)
    }

    rootContainer.register {
        LevelTwo(levelOne: $0)
    }

    rootContainer.register(factory: ConcreteB.init)

    rootContainer.register { (x: DependancyX) -> DependancyWithInputB in
      DependancyWithInputB(x:x)
    }.implements(Servicable.self)

    let concreteB: Servicable = try! rootContainer.resolve() as Servicable
    print(concreteB)
    if exectued {
      return
    }
  }
  

  /**
   Protocol forwarding can be overriden by children.
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

  class TestInjected<T> : AutoInjectedPropertyBox {
    ///The type of wrapped property.
    public static var wrappedType: Any.Type {
      return T.self
    }

    var containerUsedInResolve : DependencyContainer?

    func resolve(_ container: DependencyContainer) throws {
      containerUsedInResolve = container
    }
  }

  class LevelTwoInjected {
    let levelOne = TestInjected<LevelOne>()
  }
  

  /**
  * Ensure that when a container itself is used as an implicit dependency it
  * injects the container that initiated the resolve() call. Additionally ensure that the resolving container
  * is passed in during calls to Resolvable protocols, resolveProperties { ... } invocations and Injected<T> properties
  */
  func testContainerAsDependenciesAlwaysUsesResolvingContainer(){

    var levelThreeContainer : DependencyContainer!

    let levelOneContainer = DependencyContainer()
    levelOneContainer.register { (container:DependencyContainer) -> LevelOne in
      XCTAssert(levelThreeContainer === container)
      return LevelOne(title:try container.resolve())
    }

    let levelTwoContainer = DependencyContainer(parent: levelOneContainer)
    levelTwoContainer.register { (container:DependencyContainer) in
      XCTAssert(levelThreeContainer === container)
      return LevelTwo(levelOne: try container.resolve())
    }.resolvingProperties { (container:DependencyContainer, levelTwo:LevelTwo) in
      XCTAssert(levelThreeContainer === container)
      XCTAssert(levelTwo.levelOne === (try container.resolve() as LevelOne))
    }

    levelTwoContainer.register { LevelTwoInjected() }

    levelThreeContainer = DependencyContainer(parent: levelTwoContainer)
    levelThreeContainer.register {
      "OccursInLevelThree"
    }


    let levelTwo = try? levelThreeContainer.resolve() as LevelTwo
    XCTAssertNotNil(levelTwo)
    XCTAssert(levelTwo?.levelOne.title == "OccursInLevelThree")

    XCTAssertNotNil(levelTwo?.resolvedInjectedContainer)
    XCTAssert(levelThreeContainer === levelTwo?.resolvedInjectedContainer)


    guard let levelTwoInjected = try? levelThreeContainer.resolve() as LevelTwoInjected else {
      XCTFail("Failed to create LevelTwoInjected")
      return
    }

    XCTAssertTrue(levelTwoInjected.levelOne.containerUsedInResolve === levelThreeContainer)

  }


  class WireFrame {
    let title: String
    let presenter: Presenter
    let viewController: ViewController

    init(presenter: Presenter, viewController: ViewController, title: String){
      self.title = title
      self.presenter = presenter
      self.viewController = viewController
    }
  }

  class Presenter {
    var wireFrame:  WireFrame?
    var viewController : ViewController?
  }

  class ViewController {
    let presenter: Presenter
    init(presenter:Presenter){
      self.presenter = presenter

    }
  }

  /**
  * Attempting to resolve from a child container may be resolved in a parent container several time.
  * This value should be reused where appropriate.
  */
  func testReusedDependenciesFoundInParentContainers() {

    let container = DependencyContainer()

    container.register {
      ViewController(presenter: $0)
    }

    container.register {
      Presenter()
    }.resolvingProperties { (container, presenter) in
      presenter.viewController = try container.resolve()
      presenter.wireFrame = try container.resolve()
    }

    var count = 0
    container.register { (presenter: Presenter, viewController: ViewController, title: String) -> WireFrame in
      count = count + 1
      return WireFrame(presenter: presenter, viewController: viewController, title: "\(title):\(count)") as WireFrame
    }

    let childContainer = DependencyContainer(parent: container)
    childContainer.register {
      "Title"
    }

    guard let wireFrame = try? childContainer.resolve() as WireFrame else {
      XCTFail()
      return
    }
    XCTAssert(wireFrame.presenter.wireFrame === wireFrame)
    XCTAssert(count == 1)
    XCTAssertEqual("Title:1", wireFrame.title)
  }

  /**
  *  Esnure that once instance of the class is constructed when the class is 
  *  registered in the child container.
  */
  func testOnlyConstructOnceWhenRegisteredInChildContainer() {

    var count = 0
    let rootContainer = DependencyContainer()
    rootContainer.register { () -> LevelOne in
      count = count + 1
      return LevelOne(title: "OccursInRoot")
    }

    let childContainer = DependencyContainer(parent: rootContainer)
    childContainer.register { (instanceOne : LevelOne, instanceTwo : LevelOne) -> LevelTwo in
      XCTAssert(instanceOne === instanceTwo)
      return LevelTwo(levelOne: instanceOne)
    }

    let levelTwo : LevelTwo? = try? childContainer.resolve()
    XCTAssertNotNil(levelTwo)
    XCTAssertEqual(count, 1)
    XCTAssertEqual(levelTwo?.resolveCount, 1)
  }

  /**
  *  Esnure that once instance of the class is constructed when the class is
  *  registered in the Parent container.
  */
  func testOnlyConstructOnceWhenRegisteredInParentContainer() {

    var count = 0
    let rootContainer = DependencyContainer()
    rootContainer.register { () -> LevelOne in
      count = count + 1
      return LevelOne(title: "OccursInRoot")
    }

    rootContainer.register { (instanceOne : LevelOne, instanceTwo : LevelOne) -> LevelTwo in
      XCTAssert(instanceOne === instanceTwo)
      return LevelTwo(levelOne: instanceOne)
    }

    let childContainer = DependencyContainer(parent: rootContainer)
    let levelTwo : LevelTwo? = try? childContainer.resolve()
    XCTAssertNotNil(levelTwo)
    XCTAssertEqual(count, 1)
    XCTAssertEqual(levelTwo?.resolveCount, 1)
  }
}
