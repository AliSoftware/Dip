import XCTest
@testable import DipTests

XCTMain([
  testCase(DipTests.allTests),
  testCase(DefinitionTests.allTests),
  testCase(RuntimeArgumentsTests.allTests),
  testCase(ComponentScopeTests.allTests),
  testCase(AutoInjectionTests.allTests),
//  testCase(ThreadSafetyTests.allTests),
  testCase(AutoWiringTests.allTests),
  testCase(ContextTests.allTests),
  testCase(TypeForwardingTests.allTests)
])
