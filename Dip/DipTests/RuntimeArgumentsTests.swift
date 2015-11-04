//
//  RuntimeArgumentsTests.swift
//  Dip
//
//  Created by Ilya Puchka on 04.11.15.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import XCTest
@testable import Dip

class RuntimeArgumentsTests: XCTestCase {
    
    let container = DependencyContainer()
    
    override func setUp() {
        super.setUp()
        container.reset()
    }
    
    func testThatItResolvesInstanceWithOneArgument() {
        //given
        let arg1 = 1
        container.register { (a1: Int) -> Service in
            XCTAssertEqual(a1, arg1)
            return ServiceImp1()
        }
        
        //when
        let service = container.resolve(arg1) as Service
        
        //then
        XCTAssertTrue(service is ServiceImp1)
    }
    
    func testThatItResolvesInstanceWithTwoArguments() {
        //given
        let arg1 = 1, arg2 = 2
        container.register { (a1: Int, a2: Int) -> Service in
            XCTAssertEqual(a1, arg1)
            XCTAssertEqual(a2, arg2)
            return ServiceImp1()
        }
        
        //when
        let service = container.resolve(arg1, arg2) as Service
        
        //then
        XCTAssertTrue(service is ServiceImp1)
    }

    func testThatItResolvesInstanceWithThreeArguments() {
        let arg1 = 1, arg2 = 2, arg3 = 3
        container.register { (a1: Int, a2: Int, a3: Int) -> Service in
            XCTAssertEqual(a1, arg1)
            XCTAssertEqual(a2, arg2)
            XCTAssertEqual(a3, arg3)
            return ServiceImp1()
        }
        
        //when
        let service = container.resolve(arg1, arg2, arg3) as Service
        
        //then
        XCTAssertTrue(service is ServiceImp1)
    }
    
    func testThatItResolvesInstanceWithFourArguments() {
        let arg1 = 1, arg2 = 2, arg3 = 3, arg4 = 4
        container.register { (a1: Int, a2: Int, a3: Int, a4: Int) -> Service in
            XCTAssertEqual(a1, arg1)
            XCTAssertEqual(a2, arg2)
            XCTAssertEqual(a3, arg3)
            XCTAssertEqual(a4, arg4)
            return ServiceImp1()
        }
        
        //when
        let service = container.resolve(arg1, arg2, arg3, arg4) as Service
        
        //then
        XCTAssertTrue(service is ServiceImp1)
    }
    
    func testThatItResolvesInstanceWithFiveArguments() {
        let arg1 = 1, arg2 = 2, arg3 = 3, arg4 = 4, arg5 = 5
        container.register { (a1: Int, a2: Int, a3: Int, a4: Int, a5: Int) -> Service in
            XCTAssertEqual(a1, arg1)
            XCTAssertEqual(a2, arg2)
            XCTAssertEqual(a3, arg3)
            XCTAssertEqual(a4, arg4)
            XCTAssertEqual(a5, arg5)
            return ServiceImp1()
        }
        
        //when
        let service = container.resolve(arg1, arg2, arg3, arg4, arg5) as Service
        
        //then
        XCTAssertTrue(service is ServiceImp1)
    }
    
    func testThatItResolvesInstanceWithSixArguments() {
        let arg1 = 1, arg2 = 2, arg3 = 3, arg4 = 4, arg5 = 5, arg6 = 6
        container.register { (a1: Int, a2: Int, a3: Int, a4: Int, a5: Int, a6: Int) -> Service in
            XCTAssertEqual(a1, arg1)
            XCTAssertEqual(a2, arg2)
            XCTAssertEqual(a3, arg3)
            XCTAssertEqual(a4, arg4)
            XCTAssertEqual(a5, arg5)
            XCTAssertEqual(a6, arg6)
            return ServiceImp1()
        }
        
        //when
        let service = container.resolve(arg1, arg2, arg3, arg4, arg5, arg6) as Service
        
        //then
        XCTAssertTrue(service is ServiceImp1)
    }
    
    func testThatItRegistersDifferentFactoriesForDifferentNumberOfArguments() {
        //given
        let arg1 = 1, arg2 = 2
        container.register { (a1: Int) in ServiceImp1() as Service }
        container.register { (a1: Int, a2: Int) in ServiceImp2() as Service }
        
        //when
        let service1 = container.resolve(arg1) as Service
        let service2 = container.resolve(arg1, arg2) as Service
        
        //then
        XCTAssertTrue(service1 is ServiceImp1)
        XCTAssertTrue(service2 is ServiceImp2)
    }
    
    func testThatItRegistersDifferentFactoriesForDifferentTypesOfArguments() {
        //given
        let arg1 = 1, arg2 = "string"
        container.register { (a1: Int) in ServiceImp1() as Service }
        container.register { (a1: String) in ServiceImp2() as Service }
        
        //when
        let service1 = container.resolve(arg1) as Service
        let service2 = container.resolve(arg2) as Service
        
        //then
        XCTAssertTrue(service1 is ServiceImp1)
        XCTAssertTrue(service2 is ServiceImp2)
    }
    
    func testThatItRegistersDifferentFactoriesForDifferentOrderOfArguments() {
        //given
        let arg1 = 1, arg2 = "string"
        container.register { (a1: Int, a2: String) in ServiceImp1() as Service }
        container.register { (a1: String, a2: Int) in ServiceImp2() as Service }
        
        //when
        let service1 = container.resolve(arg1, arg2) as Service
        let service2 = container.resolve(arg2, arg1) as Service
        
        //then
        XCTAssertTrue(service1 is ServiceImp1)
        XCTAssertTrue(service2 is ServiceImp2)
    }
    
    func testThatNewRegistrationWithSameArgumentsOverridesPreviousRegistration() {
        //given
        let arg1 = 1, arg2 = 2
        container.register { (a1: Int, a2: Int) in ServiceImp1() as Service }
        let service1 = container.resolve(arg1, arg2) as Service
        
        //when
        container.register { (a1: Int, a2: Int) in ServiceImp2() as Service }
        let service2 = container.resolve(arg1, arg2) as Service
        
        //then
        XCTAssertTrue(service1 is ServiceImp1)
        XCTAssertTrue(service2 is ServiceImp2)
    }

}
