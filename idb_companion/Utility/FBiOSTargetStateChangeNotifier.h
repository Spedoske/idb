/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBControlCore.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSimulatorSet;
@class FBDeviceSet;

/**
 A component that is repsonsible for notifying of updates to changes in the availability of iOS Targets.
 */
@interface FBiOSTargetStateChangeNotifier : NSObject

#pragma mark Initializers

/**
 The designated initializer.

 @param filePath the filepath to write the updates to. This
 @param simulatorSet the simulator set to monitor.
 @param deviceSet the device set to monitor.
 @param logger the logger to log to.
 @return a future that resolves when the notifier is created.
 */
+ (FBFuture<FBiOSTargetStateChangeNotifier *> *)notifierToFilePath:(NSString *)filePath simulatorSet:(FBSimulatorSet *)simulatorSet deviceSet:(FBDeviceSet *)deviceSet logger:(id<FBControlCoreLogger>)logge;

#pragma mark Public Methods

/**
 Start the Notifier. Will also first report the initial state of the provided sets.

 @return a Future that resolves when the notifier has started
 */
- (FBFuture<NSNull *> *)startNotifier;

#pragma mark Properties

/**
 A Future that resolves when the notifier has stopped notifying.
*/
@property (nonatomic, strong, readonly) FBFuture<NSNull *> *notifierDone;

@end

NS_ASSUME_NONNULL_END
