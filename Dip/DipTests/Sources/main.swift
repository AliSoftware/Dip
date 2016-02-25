import XCTest

XCTMain([
  DipTests(), 
  DefinitionTests(), 
  RuntimeArgumentsTests(), 
  ComponentScopeTests(),
  AutoInjectionTests(),
  ThreadSafetyTests()
])
