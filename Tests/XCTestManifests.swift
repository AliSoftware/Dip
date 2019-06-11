#if !canImport(ObjectiveC)
import XCTest

extension AutoInjectionTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AutoInjectionTests = [
        ("testThatItAutoInjectsPropertyWithCollaboratingContainer", testThatItAutoInjectsPropertyWithCollaboratingContainer),
        ("testThatItCallsDidInjectOnAutoInjectedProperty", testThatItCallsDidInjectOnAutoInjectedProperty),
        ("testThatItCallsResolveDependencyBlockWhenAutoInjecting", testThatItCallsResolveDependencyBlockWhenAutoInjecting),
        ("testThatItDoesNotPassTagToAutoInjectedPropertyWithExplicitTag", testThatItDoesNotPassTagToAutoInjectedPropertyWithExplicitTag),
        ("testThatItPassesTagToAutoInjectedProperty", testThatItPassesTagToAutoInjectedProperty),
        ("testThatItResolvesAutoInjectedDependencies", testThatItResolvesAutoInjectedDependencies),
        ("testThatItResolvesAutoInjectedSingletons", testThatItResolvesAutoInjectedSingletons),
        ("testThatItResolvesInheritedDependencies", testThatItResolvesInheritedDependencies),
        ("testThatItResolvesTaggedAutoInjectedProperties", testThatItResolvesTaggedAutoInjectedProperties),
        ("testThatItReusesAutoInjectedInstancesOnNextResolveOrAutoInjection", testThatItReusesAutoInjectedInstancesOnNextResolveOrAutoInjection),
        ("testThatItReusesResolvedAutoInjectedInstances", testThatItReusesResolvedAutoInjectedInstances),
        ("testThatItThrowsErrorIfFailsToAutoInjectDependency", testThatItThrowsErrorIfFailsToAutoInjectDependency),
        ("testThatNoErrorThrownWhenOptionalPropertiesAreNotAutoInjected", testThatNoErrorThrownWhenOptionalPropertiesAreNotAutoInjected),
        ("testThatThereIsNoRetainCycleBetweenAutoInjectedCircularDependencies", testThatThereIsNoRetainCycleBetweenAutoInjectedCircularDependencies),
    ]
}

extension AutoWiringTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AutoWiringTests = [
        ("testThatItCanAutoWireOptional", testThatItCanAutoWireOptional),
        ("testThatItCanResolveWithAutoWiring", testThatItCanResolveWithAutoWiring),
        ("testThatItDoesNotReuseInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithAnotherTag", testThatItDoesNotReuseInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithAnotherTag),
        ("testThatItDoesNotTryToUseAutoWiringWhenCallingResolveWithArguments", testThatItDoesNotTryToUseAutoWiringWhenCallingResolveWithArguments),
        ("testThatItDoesNotUseAutoWiringWhenFailedToResolveLowLevelDependency", testThatItDoesNotUseAutoWiringWhenFailedToResolveLowLevelDependency),
        ("testThatItFallbackToNotTaggedFactoryWhenUsingAutoWire", testThatItFallbackToNotTaggedFactoryWhenUsingAutoWire),
        ("testThatItPrefersTaggedFactoryWithDifferentNumberOfArgumentsWhenUsingAutoWire", testThatItPrefersTaggedFactoryWithDifferentNumberOfArgumentsWhenUsingAutoWire),
        ("testThatItPrefersTaggedFactoryWithDifferentTypesOfArgumentsWhenUsingAutoWire", testThatItPrefersTaggedFactoryWithDifferentTypesOfArgumentsWhenUsingAutoWire),
        ("testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgain", testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgain),
        ("testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithTheSameTag", testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithTheSameTag),
        ("testThatItReusesInstancesResolvedWithoutAutoWiringWhenUsingAutoWiringAgain", testThatItReusesInstancesResolvedWithoutAutoWiringWhenUsingAutoWiringAgain),
        ("testThatItThrowsAmbiguityErrorWhenUsingAutoWire", testThatItThrowsAmbiguityErrorWhenUsingAutoWire),
        ("testThatItUsesAutoWireFactoryWithMostNumberOfArguments", testThatItUsesAutoWireFactoryWithMostNumberOfArguments),
        ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith1Argument", testThatItUsesTagToResolveDependenciesWithAutoWiringWith1Argument),
        ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith2Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith2Arguments),
        ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith3Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith3Arguments),
        ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith4Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith4Arguments),
        ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith5Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith5Arguments),
        ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith6Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith6Arguments),
    ]
}

extension ComponentScopeTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ComponentScopeTests = [
        ("testThatCollaboratingContainersReuseSingletonsResolvedByAnotherContainer", testThatCollaboratingContainersReuseSingletonsResolvedByAnotherContainer),
        ("testThatContainerCanBeBootstrappedAgainAfterReset", testThatContainerCanBeBootstrappedAgainAfterReset),
        ("testThatItDoesNotReuseInstanceInSharedScopeInNextResolve", testThatItDoesNotReuseInstanceInSharedScopeInNextResolve),
        ("testThatItDoesNotReuseInstanceInSharedScopeResolvedForNilTagWhenResolvingForAnotherTag", testThatItDoesNotReuseInstanceInSharedScopeResolvedForNilTagWhenResolvingForAnotherTag),
        ("testThatItHoldsWeakReferenceToWeakSingletonInstance", testThatItHoldsWeakReferenceToWeakSingletonInstance),
        ("testThatItResolvesTypeAsNewInstanceForUniqueScope", testThatItResolvesTypeAsNewInstanceForUniqueScope),
        ("testThatItResolvesWeakSingletonAgainAfterItWasReleased", testThatItResolvesWeakSingletonAgainAfterItWasReleased),
        ("testThatItReusesInstanceForSingletonScope", testThatItReusesInstanceForSingletonScope),
        ("testThatItReusesInstanceInSharedScopeDuringResolve", testThatItReusesInstanceInSharedScopeDuringResolve),
        ("testThatItReusesInstanceInSharedScopeResolvedForNilTag", testThatItReusesInstanceInSharedScopeResolvedForNilTag),
        ("testThatItReusesResolvedInstanceWhenResolvingOptional", testThatItReusesResolvedInstanceWhenResolvingOptional),
        ("testThatOnlyEagerSingletonIsCreatedWhenContainerIsBootsrapped", testThatOnlyEagerSingletonIsCreatedWhenContainerIsBootsrapped),
        ("testThatScopeCanBeChanged", testThatScopeCanBeChanged),
        ("testThatSharedIsDefaultScope", testThatSharedIsDefaultScope),
        ("testThatSingletonIsNotReusedAcrossContainers", testThatSingletonIsNotReusedAcrossContainers),
        ("testThatSingletonIsReleasedWhenContainerIsReset", testThatSingletonIsReleasedWhenContainerIsReset),
        ("testThatSingletonIsReleasedWhenDefinitionIsOverridden", testThatSingletonIsReleasedWhenDefinitionIsOverridden),
        ("testThatSingletonIsReleasedWhenDefinitionIsRemoved", testThatSingletonIsReleasedWhenDefinitionIsRemoved),
    ]
}

extension ContextTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ContextTests = [
        ("testThatContextDoesNotOverrideNilTagPassedToResolve", testThatContextDoesNotOverrideNilTagPassedToResolve),
        ("testThatContextIsPreservedWhenResolvingWithCollaboration", testThatContextIsPreservedWhenResolvingWithCollaboration),
        ("testThatContextStoresCurrentlyResolvedType", testThatContextStoresCurrentlyResolvedType),
        ("testThatContextStoresInjectedInType", testThatContextStoresInjectedInType),
        ("testThatContextStoresNameOfAutoInjectedProperty", testThatContextStoresNameOfAutoInjectedProperty),
        ("testThatContextStoresTheTagPassedToResolve", testThatContextStoresTheTagPassedToResolve),
        ("testThatContextStoresTheTagPassedToResolveWhenAutoInjecting", testThatContextStoresTheTagPassedToResolveWhenAutoInjecting),
        ("testThatContextStoresTheTagPassedToResolveWhenAutoWiring", testThatContextStoresTheTagPassedToResolveWhenAutoWiring),
        ("testThatItDoesNotSetInjectedInTypeWhenResolvingWithCollaboration", testThatItDoesNotSetInjectedInTypeWhenResolvingWithCollaboration),
    ]
}

extension DefinitionTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__DefinitionTests = [
        ("testThatDefinitionKeyIsEqualBy_Type_Factory_Tag", testThatDefinitionKeyIsEqualBy_Type_Factory_Tag),
        ("testThatDefinitionKeysWithDifferentFactoriesAreNotEqual", testThatDefinitionKeysWithDifferentFactoriesAreNotEqual),
        ("testThatDefinitionKeysWithDifferentTagsAreNotEqual", testThatDefinitionKeysWithDifferentTagsAreNotEqual),
        ("testThatDefinitionKeysWithDifferentTypesAreNotEqual", testThatDefinitionKeysWithDifferentTypesAreNotEqual),
        ("testThatItRegisteresOptionalTypesAsForwardedTypes", testThatItRegisteresOptionalTypesAsForwardedTypes),
        ("testThatResolveDependenciesBlockIsNotCalledWhenPassedWrongInstance", testThatResolveDependenciesBlockIsNotCalledWhenPassedWrongInstance),
        ("testThatResolveDependenciesCallsResolveDependenciesBlock", testThatResolveDependenciesCallsResolveDependenciesBlock),
    ]
}

extension DipTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__DipTests = [
        ("testItCallsResolveDependenciesOnResolableInstance", testItCallsResolveDependenciesOnResolableInstance),
        ("testThatCollaboratingContainersAreWeakReferences", testThatCollaboratingContainersAreWeakReferences),
        ("testThatCollaboratingContainersReuseInstancesResolvedByAnotherContainer", testThatCollaboratingContainersReuseInstancesResolvedByAnotherContainer),
        ("testThatCollaboratingWithSelfIsIgnored", testThatCollaboratingWithSelfIsIgnored),
        ("testThatCollaborationReferencesAreRecursivelyUpdate", testThatCollaborationReferencesAreRecursivelyUpdate),
        ("testThatContainerAutowireBeforeCollaboration", testThatContainerAutowireBeforeCollaboration),
        ("testThatContainersShareTheirSingletonsOnlyWithCollaborators", testThatContainersShareTheirSingletonsOnlyWithCollaborators),
        ("testThatCreatingContainerWithConfigBlockDoesNotCreateRetainCycle", testThatCreatingContainerWithConfigBlockDoesNotCreateRetainCycle),
        ("testThatItCallsDidResolveDependenciesInReverseOrder", testThatItCallsDidResolveDependenciesInReverseOrder),
        ("testThatItCallsDidResolveDependenciesOnResolvableIntance", testThatItCallsDidResolveDependenciesOnResolvableIntance),
        ("testThatItCallsResolveDependenciesOnDefinition", testThatItCallsResolveDependenciesOnDefinition),
        ("testThatItCanHandleSeparateContainersAndTheirCollaboration", testThatItCanHandleSeparateContainersAndTheirCollaboration),
        ("testThatItCanResolveUsingContainersCollaboration", testThatItCanResolveUsingContainersCollaboration),
        ("testThatItFailsValidationIfNoMatchingArgumentsFound", testThatItFailsValidationIfNoMatchingArgumentsFound),
        ("testThatItFailsValidationOnlyForDipErrors", testThatItFailsValidationOnlyForDipErrors),
        ("testThatItPicksRuntimeArgumentsWhenValidatingConfiguration", testThatItPicksRuntimeArgumentsWhenValidatingConfiguration),
        ("testThatItResolvesCircularDependencies", testThatItResolvesCircularDependencies),
        ("testThatItResolvesDifferentInstancesRegisteredForDifferentTags", testThatItResolvesDifferentInstancesRegisteredForDifferentTags),
        ("testThatItResolvesInstanceRegisteredWithoutTag", testThatItResolvesInstanceRegisteredWithoutTag),
        ("testThatItResolvesInstanceRegisteredWithTag", testThatItResolvesInstanceRegisteredWithTag),
        ("testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments", testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments),
        ("testThatItThrowsErrorIfCanNotFindDefinitionForTag", testThatItThrowsErrorIfCanNotFindDefinitionForTag),
        ("testThatItThrowsErrorIfCanNotFindDefinitionForType", testThatItThrowsErrorIfCanNotFindDefinitionForType),
        ("testThatItThrowsErrorIfConstructorThrows", testThatItThrowsErrorIfConstructorThrows),
        ("testThatItThrowsErrorIfFailsToResolveDependency", testThatItThrowsErrorIfFailsToResolveDependency),
        ("testThatItValidatesConfiguration", testThatItValidatesConfiguration),
        ("testThatNewRegistrationOverridesPreviousRegistration", testThatNewRegistrationOverridesPreviousRegistration),
    ]
}

extension RuntimeArgumentsTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RuntimeArgumentsTests = [
        ("testThatDifferentFactoriesRegisteredIfArgumentIsOptional", testThatDifferentFactoriesRegisteredIfArgumentIsOptional),
        ("testThatItRegistersDifferentFactoriesForDifferentNumberOfArguments", testThatItRegistersDifferentFactoriesForDifferentNumberOfArguments),
        ("testThatItRegistersDifferentFactoriesForDifferentOrderOfArguments", testThatItRegistersDifferentFactoriesForDifferentOrderOfArguments),
        ("testThatItRegistersDifferentFactoriesForDifferentTypesOfArguments", testThatItRegistersDifferentFactoriesForDifferentTypesOfArguments),
        ("testThatItResolvesInstanceWithFiveArguments", testThatItResolvesInstanceWithFiveArguments),
        ("testThatItResolvesInstanceWithFourArguments", testThatItResolvesInstanceWithFourArguments),
        ("testThatItResolvesInstanceWithOneArgument", testThatItResolvesInstanceWithOneArgument),
        ("testThatItResolvesInstanceWithSixArguments", testThatItResolvesInstanceWithSixArguments),
        ("testThatItResolvesInstanceWithThreeArguments", testThatItResolvesInstanceWithThreeArguments),
        ("testThatItResolvesInstanceWithTwoArguments", testThatItResolvesInstanceWithTwoArguments),
        ("testThatNewRegistrationWithSameArgumentsOverridesPreviousRegistration", testThatNewRegistrationWithSameArgumentsOverridesPreviousRegistration),
    ]
}

extension ThreadSafetyTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ThreadSafetyTests = [
        ("testCircularReferenceThreadSafety", testCircularReferenceThreadSafety),
        ("testFactoryThreadSafety", testFactoryThreadSafety),
        ("testSingletonThreadSafety", testSingletonThreadSafety),
    ]
}

extension TypeForwardingTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TypeForwardingTests = [
        ("testThatItCallsResolvedDependenciesBlockProvidedAfterRegistrationWhenResolvingByTypeForwarding", testThatItCallsResolvedDependenciesBlockProvidedAfterRegistrationWhenResolvingByTypeForwarding),
        ("testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding", testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding),
        ("testThatItCanResolveOptional", testThatItCanResolveOptional),
        ("testThatItDoesNotOverrideIfDefinitionForwardsTheSameTypeWithDifferentTag", testThatItDoesNotOverrideIfDefinitionForwardsTheSameTypeWithDifferentTag),
        ("testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag", testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag),
        ("testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag", testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag),
        ("testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding", testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding),
        ("testThatItFirstUsesTaggedDefinitionWhenResolvingOptional", testThatItFirstUsesTaggedDefinitionWhenResolvingOptional),
        ("testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType", testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType),
        ("testThatItResolvesInstanceByTypeForwarding", testThatItResolvesInstanceByTypeForwarding),
        ("testThatItReusesInstanceResolvedByTypeForwarding", testThatItReusesInstanceResolvedByTypeForwarding),
        ("testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding", testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AutoInjectionTests.__allTests__AutoInjectionTests),
        testCase(AutoWiringTests.__allTests__AutoWiringTests),
        testCase(ComponentScopeTests.__allTests__ComponentScopeTests),
        testCase(ContextTests.__allTests__ContextTests),
        testCase(DefinitionTests.__allTests__DefinitionTests),
        testCase(DipTests.__allTests__DipTests),
        testCase(RuntimeArgumentsTests.__allTests__RuntimeArgumentsTests),
        testCase(ThreadSafetyTests.__allTests__ThreadSafetyTests),
        testCase(TypeForwardingTests.__allTests__TypeForwardingTests),
    ]
}
#endif
