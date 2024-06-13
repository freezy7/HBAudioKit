//
//  HBAudioKit.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAudioKit.h"
#import "HBAKSettings.h"
#import <AudioToolbox/AudioUnit.h>
#import <Accelerate/Accelerate.h>
#import "HBAudioSession.h"
#import <UIKit/UIKit.h>

@implementation HBAudioKit

static AVAudioEngine *AKAudioEngine = nil;
+ (AVAudioEngine *)engine {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AKAudioEngine = [AVAudioEngine new];
    });
    
    if (HBAKSettings.audioInputEnabled) {
        [AKAudioEngine inputNode];
    }
    
    [self deviceSampleRate];
    
    return AKAudioEngine;
}

static BOOL AKShouldBeRunning = NO;
+ (BOOL)shouldBeRunning {
    return AKShouldBeRunning;
}

+ (void)setShouldBeRunning:(BOOL)shouldBeRunning {
    AKShouldBeRunning = shouldBeRunning;
}

static HBAKMixer *_innerFinalMixer = nil;
+ (void)setFinalMixer:(HBAKMixer *)finalMixer {
    _innerFinalMixer = finalMixer;
}

+ (HBAKMixer *)finalMixer {
    return _innerFinalMixer;
}

static HBAKNode *_innerOutput = nil;
+ (void)setOutput:(HBAKNode *)output {
    _innerOutput = output;
    
    NSError *error = nil;
    [self updateSessionCategoryAndOptions:&error];
    
    if ([output isKindOfClass:HBAKMixer.class]) {
        [self setFinalMixer:(HBAKMixer *)output];
    } else {
        HBAKMixer *mixer = [HBAKMixer new];
        [output connectToNode:mixer];
        [self setFinalMixer:mixer];
    }
    if (_innerFinalMixer) {
        [[self engine] connect:_innerFinalMixer.avAudioNode to:[self engine].outputNode format:[HBAKSettings audioFormat]];
    }
}

+ (HBAKNode *)output {
    return _innerOutput;
}


+ (double)deviceSampleRate {
    return [AVAudioSession sharedInstance].sampleRate;
}

+ (void)connectNode1:(AVAudioNode *)node1 toNode2:(AVAudioNode *)node2 fromBus1:(AVAudioNodeBus)bus1 toBus2:(AVAudioNodeBus)bus2 format:(AVAudioFormat *)format {
    [self safeAttachNodes:@[node1, node2]];
    
    AVAudioNode *dummyNode = [self addDummyOnEmptyMixerNode:node1];
    [[self engine] connect:node1 to:node2 fromBus:bus1 toBus:bus2 format:format];
    
    if (dummyNode) {
        [[self engine] disconnectNodeOutput:dummyNode];
    }
}

+ (void)safeAttachNodes:(NSArray <AVAudioNode *> *)nodes {
    [[nodes hb_filterElements:^BOOL(AVAudioNode * _Nonnull elemtent) {
        return !elemtent.engine;
    }] hb_map:^id _Nullable(AVAudioNode * _Nonnull obj) {
        [HBAudioKit.engine attachNode:obj];
        return obj;
    }];
}

+ (AVAudioNode *)addDummyOnEmptyMixerNode:(AVAudioNode *)node {
    if ([node isKindOfClass:AVAudioMixerNode.class] && [self engine].isRunning) {
        BOOL contain = NO;
        for (int i = 0; i < node.numberOfInputs; i++) {
            if ([[self engine] inputConnectionPointForNode:node inputBus:0] != nil) {
                contain = YES;
                break;
            }
        }
        if (!contain) {
            return nil;
        }
        
        AVAudioUnitSampler *dummy = [AVAudioUnitSampler new];
        [[self engine] attachNode:dummy];
        [[self engine] connect:dummy to:node format:HBAudioKit.format];
        return dummy;
    }
    
    return nil;
}

+ (void)setInputDevice:(HBAKDevice *)device {
    AVAudioSessionPortDescription *portDescription = device.portDescription;
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setPreferredInput:portDescription error:&error];
    
    AVAudioSessionDataSourceDescription *dataSourceDescription = device.dataSource;
    if (dataSourceDescription) {
        [[AVAudioSession sharedInstance] setInputDataSource:dataSourceDescription error:&error];
    }
}

#pragma mark - Status

// Global audio format (44.1K, Stereo)
+ (AVAudioFormat *)format {
    return HBAKSettings.audioFormat;
}

- (BOOL)isIAAConnected {
    
    UInt32 dataSize;
    Boolean writable;
    UInt32 result = AudioUnitGetPropertyInfo(HBAudioKit.engine.outputNode.audioUnit, kAudioUnitProperty_IsInterAppConnected, kAudioUnitScope_Global, 0, &dataSize, &writable);
    
    UInt32 data;
    result = AudioUnitGetProperty(HBAudioKit.engine.outputNode.audioUnit, kAudioUnitProperty_IsInterAppConnected, kAudioUnitScope_Global, 0, &data, &dataSize);
    
    if (result == 1) {
        return YES;
    }
    
    return false;
}

#pragma mark - safe connections

+ (void)connectSourceNode:(AVAudioNode *)sourceNode toDestNodes:(NSArray <AVAudioConnectionPoint *> *)destNodes fromSourceBus:(AVAudioNodeBus)sourceBus format:(AVAudioFormat *)format {
    NSArray <AVAudioConnectionPoint *> *connectionsWithNodes = [destNodes hb_filterElements:^BOOL(AVAudioConnectionPoint * _Nonnull elemtent) {
        return elemtent.node != nil;
    }];
    NSArray <AVAudioNode *> *connectionNodes = [connectionsWithNodes hb_map:^id _Nullable(AVAudioConnectionPoint * _Nonnull obj) {
        return obj.node;
    }];
    
    if (!sourceNode || destNodes.count  <= 0) {
        NSLog(@"--------------- nil node");
        return;
    }
    
    [self safeAttachNodes:@[sourceNode]];
    [self safeAttachNodes:connectionNodes];
    
    AVAudioNode *dummyNode = [self addDummyOnEmptyMixerNode:sourceNode];
    [self checkMixerInputsConnectionPoints:connectionsWithNodes];
    
    [[self engine] connect:sourceNode toConnectionPoints:connectionsWithNodes fromBus:sourceBus format:format];
    if (dummyNode) {
        [[self engine] disconnectNodeOutput:dummyNode];
    }
}

+ (void)checkMixerInputsConnectionPoints:(NSArray <AVAudioConnectionPoint *> *)connectionPoints {
    if (![self engine].isRunning) {
        return;
    }
    
    for (AVAudioConnectionPoint *connection in connectionPoints) {
        AVAudioMixerNode *mixer = (AVAudioMixerNode *)connection.node;
        if ([mixer isKindOfClass:AVAudioMixerNode.class] && connection.bus >= mixer.numberOfInputs) {
            NSMutableArray <AVAudioNode *> *dummyNodes = [NSMutableArray array];
            while (connection.bus >= mixer.numberOfInputs) {
                AVAudioUnitSampler *dummy = [AVAudioUnitSampler new];
                [self connectNode1:dummy toNode2:mixer fromBus1:0 toBus2:mixer.nextAvailableInputBus format:[self format]];
                
                [dummyNodes hb_safeAddObject:dummy];
            }
            
            for (AVAudioNode * _Nonnull elemtent in dummyNodes) {
                [HBAudioKit.engine disconnectNodeOutput:elemtent];
            }
        }
    }
}

+ (void)detachNodes:(NSArray <AVAudioNode *> *)nodes {
    for (AVAudioNode *node in nodes) {
        [self.engine detachNode:node];
    }
}

#pragma mark - Start/Stop

+ (void)startAndReturnError:(NSError **)error {
    
    [[self engine] prepare];
    
    if (![HBAKSettings disableAVAudioSessionCategoryManagement]) {
        [self updateSessionCategoryAndOptions:error];
        
        if (*error != nil) {
            return;
        }
        
        [[HBAudioSession sharedSession] setActive:YES];
        
        if (*error != nil) {
            return;
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartEngineAfterRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioEngineConfigurationChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartEngineAfterConfigurationChange:) name:AVAudioEngineConfigurationChangeNotification object:nil];
    
    [[self engine] startAndReturnError:error];
    [self setShouldBeRunning:YES];
}

+ (void)stopAndReturnError:(NSError *__autoreleasing  _Nullable *)error {
    [[self engine] startAndReturnError:error];
    [self setShouldBeRunning:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioEngineConfigurationChangeNotification object:nil];
}

+ (void)shutdownAndReturnError:(NSError *__autoreleasing  _Nullable *)error {
    AKAudioEngine = [AVAudioEngine new];
    
    _innerFinalMixer = nil;
    _innerOutput = nil;
    
    [self setShouldBeRunning:NO];
}

+ (void)disconnectAllInputs {
    if (_innerFinalMixer) {
        [[self engine] disconnectNodeInput:_innerFinalMixer.avAudioNode];
    }
}

+ (void)updateSessionCategoryAndOptions:(NSError **)error {
    if ([HBAKSettings disableAVAudioSessionCategoryManagement]) {
        return;
    }
    
    [HBAKSettings setSessionCategory:[HBAKSettings computedSessionCategory] options:[HBAKSettings computedSessionOptions] error:error];
}

+ (void)restartEngineAfterConfigurationChange:(NSNotification *)notification {
    if ([notification.object isKindOfClass:AVAudioEngine.class] && notification.object == [self engine]) {
        if ([NSThread currentThread].isMainThread) {
            [self attemptRestart];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self attemptRestart];
            });
        }
    }
}

+ (void)attemptRestart {
    if (![self engine].isRunning && AKShouldBeRunning) {
        BOOL appIsNotActive = [UIApplication sharedApplication].applicationState != UIApplicationStateActive;
        // 默认是支持背景模式的
        BOOL appDoesNotSupportBackgroundAudio = NO;
        if (appIsNotActive && appDoesNotSupportBackgroundAudio) {
            return;
        }
        
        NSError *error = nil;
        [[self engine] startAndReturnError:&error];
        if (error) {
            //
            NSLog(@"error restarting engine after route change");
        }
    }
}

+ (void)restartEngineAfterRouteChange:(NSNotification *)notification {
    if ([NSThread currentThread].isMainThread) {
        [self attemptRestart];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self attemptRestart];
        });
    }
}

+ (float)RMS:(float *)buffer length:(int)bufferSize {
    //    float sum = 0.0;
    //    for(int i = 0; i < bufferSize; i++)
    //        sum += buffer[i] * buffer[i];
    //    return sqrtf( sum / bufferSize);
    
    // Using Accelerate is faster
    float rms = 0.0;
    vDSP_rmsqv(buffer, 1, &rms, (vDSP_Length)bufferSize);
    return rms;
}

@end
