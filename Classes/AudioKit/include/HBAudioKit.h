//
//  HBAudioKit.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "HBAKDevice.h"
#import "HBAKMixer.h"
#import "HBAudioKitFastRecorder.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBAudioKit : NSObject

@property (nonatomic, class, readonly) double deviceSampleRate;

@property (nonatomic, class, readonly) AVAudioEngine *engine;

@property (nonatomic, class) HBAKMixer *finalMixer;
@property (nonatomic, class, nullable) HBAKNode *output;

+ (void)connectNode1:(AVAudioNode *)node1 toNode2:(AVAudioNode *)node2 fromBus1:(AVAudioNodeBus)bus1 toBus2:(AVAudioNodeBus)bus2 format:(AVAudioFormat *)format;

+ (void)setInputDevice:(HBAKDevice *)device;

#pragma mark - Status

@property (nonatomic, class, readonly) AVAudioFormat *format;
@property (nonatomic, class) BOOL shouldBeRunning;

- (BOOL)isIAAConnected;

#pragma mark - safe connections

+ (void)connectSourceNode:(AVAudioNode *)sourceNode toDestNodes:(NSArray <AVAudioConnectionPoint *> *)destNodes fromSourceBus:(AVAudioNodeBus)sourceBus format:(AVAudioFormat *)format;
+ (void)detachNodes:(NSArray <AVAudioNode *> *)nodes;

#pragma mark - Start/Stop

+ (void)startAndReturnError:(NSError **)error;
+ (void)stopAndReturnError:(NSError **)error;
+ (void)shutdownAndReturnError:(NSError **)error;
+ (void)disconnectAllInputs;

+ (float)RMS:(float *)buffer length:(int)bufferSize;

@end

NS_ASSUME_NONNULL_END
