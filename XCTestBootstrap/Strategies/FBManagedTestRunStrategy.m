/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBManagedTestRunStrategy.h"

#import "FBTestManagerAPIMediator.h"
#import "FBTestManagerContext.h"
#import "FBTestRunnerConfiguration.h"
#import "FBXCTestReporter.h"
#import "XCTestBootstrapError.h"
#import "XCTestBootstrapFrameworkLoader.h"

@implementation FBManagedTestRunStrategy

#pragma mark Initializers

+ (FBFuture<NSNull *> *)runToCompletionWithTarget:(id<FBiOSTarget>)target configuration:(FBTestLaunchConfiguration *)configuration shims:(FBXCTestShimConfiguration *)shims codesign:(FBCodesignProvider *)codesign workingDirectory:(NSString *)workingDirectory reporter:(id<FBXCTestReporter>)reporter logger:(id<FBControlCoreLogger>)logger
{
  NSParameterAssert(target);
  NSParameterAssert(configuration.applicationLaunchConfiguration);
  NSParameterAssert(configuration.testBundlePath);

  NSError *error = nil;
  if (![XCTestBootstrapFrameworkLoader.allDependentFrameworks loadPrivateFrameworks:target.logger error:&error]) {
    return [XCTestBootstrapError failFutureWithError:error];
  }

  FBApplicationLaunchConfiguration *applicationLaunchConfiguration = configuration.applicationLaunchConfiguration;
  return [[FBTestRunnerConfiguration
    prepareConfigurationWithTarget:target testLaunchConfiguration:configuration shims:shims workingDirectory:workingDirectory codesign:codesign]
    onQueue:target.workQueue fmap:^(FBTestRunnerConfiguration *runnerConfiguration) {
      // The launch configuration for the test bundle host.
      FBApplicationLaunchConfiguration *testHostLaunchConfiguration = [self
        prepareApplicationLaunchConfiguration:applicationLaunchConfiguration
        withTestRunnerConfiguration:runnerConfiguration];

      // Make the Context for the Test Manager.
      FBTestManagerContext *context = [[FBTestManagerContext alloc]
        initWithSessionIdentifier:runnerConfiguration.sessionIdentifier
        timeout:configuration.timeout
        testHostLaunchConfiguration:testHostLaunchConfiguration
        testedApplicationAdditionalEnvironment:runnerConfiguration.testedApplicationAdditionalEnvironment];

      // Construct and run the mediator, the core of the test execution.
      return [FBTestManagerAPIMediator
        connectAndRunUntilCompletionWithContext:context
        target:target
        reporter:reporter
        logger:logger];
    }];
}

+ (FBApplicationLaunchConfiguration *)prepareApplicationLaunchConfiguration:(FBApplicationLaunchConfiguration *)applicationLaunchConfiguration withTestRunnerConfiguration:(FBTestRunnerConfiguration *)testRunnerConfiguration
{
  return [FBApplicationLaunchConfiguration
    configurationWithBundleID:testRunnerConfiguration.testRunner.identifier
    bundleName:testRunnerConfiguration.testRunner.identifier
    arguments:[self argumentsFromConfiguration:testRunnerConfiguration attributes:applicationLaunchConfiguration.arguments]
    environment:[self environmentFromConfiguration:testRunnerConfiguration environment:applicationLaunchConfiguration.environment]
    output:applicationLaunchConfiguration.output
    launchMode:FBApplicationLaunchModeFailIfRunning];
}

+ (NSArray<NSString *> *)argumentsFromConfiguration:(FBTestRunnerConfiguration *)configuration attributes:(NSArray<NSString *> *)attributes
{
  return [(configuration.launchArguments ?: @[]) arrayByAddingObjectsFromArray:(attributes ?: @[])];
}

+ (NSDictionary<NSString *, NSString *> *)environmentFromConfiguration:(FBTestRunnerConfiguration *)configuration environment:(NSDictionary<NSString *, NSString *> *)environment
{
  NSMutableDictionary<NSString *, NSString *> *mEnvironment = (configuration.launchEnvironment ?: @{}).mutableCopy;
  if (environment) {
    [mEnvironment addEntriesFromDictionary:environment];
  }
  return [mEnvironment copy];
}

@end
