//
//  HBAKBoosterAudioUnit.m
//  ProtonCrew
//
//  Created by R_style_Man on 2021/12/5.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKBoosterAudioUnit.h"

@implementation HBAKBoosterAudioUnit

- (void)setParameter:(HBAKBoosterParameter)address value:(double)value {
    [self setParameterWithAddress:address value:value];
}

- (void)setParameterImmediately:(HBAKBoosterParameter)address value:(double)value {
    [self setParameterWithAddress:address value:value];
}

- (void)setLeftGain:(double)leftGain {
    _leftGain = leftGain;
    
    [self setParameter:HBAKBoosterParameterLeftGain value:leftGain];
}

- (void)setRightGain:(double)rightGain {
    _rightGain = rightGain;
    
    [self setParameter:HBAKBoosterParameterRightGain value:rightGain];
}

- (void)setRampDuration:(double)rampDuration {
    _rampDuration = rampDuration;
    
    [self setParameter:HBAKBoosterParameterRampDuration value:rampDuration];
}

- (void)setRampType:(double)rampType {
    _rampType = rampType;
    
    [self setParameter:HBAKBoosterParameterRampType value:rampType];
}

- (HBAKDSPRef)initDSPWithSampleRate:(double)sampleRate channelCount:(AVAudioChannelCount)count {
    return createBoosterDSP(count, sampleRate);
}

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription error:(NSError *__autoreleasing  _Nullable *)outError {
    self = [super initWithComponentDescription:componentDescription error:outError];
    if (self) {
        _leftGain = 1.0;
        _rightGain = 1.0;
        _rampType = 0;
        _rampDuration = 0;
        
        AUParameter *leftGain = [AUParameter parameterWithIdentifier:@"leftGain" name:@"Left Boosting Amount" address:0 min:0 max:2.0 unit:kAudioUnitParameterUnit_LinearGain flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable|kAudioUnitParameterFlag_CanRamp];
        AUParameter *rightGain = [AUParameter parameterWithIdentifier:@"rightGain" name:@"Right Boosting Amount" address:1 min:0 max:2.0 unit:kAudioUnitParameterUnit_LinearGain flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable|kAudioUnitParameterFlag_CanRamp];
        
        [self setParameterTree:[AUParameterTree hb_treeWithChildren:@[leftGain, rightGain]]];
        
        leftGain.value = 1.0;
        rightGain.value = 1.0;
    }
    return self;
}

- (BOOL)canProcessInPlace {
    return YES;
}

@end
