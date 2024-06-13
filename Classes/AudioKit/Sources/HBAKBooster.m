//
//  HBAKBooster.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKBooster.h"
#import "HBAudioKit.h"
#import "HBAKSettings.h"
#import "HBAudioSession.h"

@interface HBAKBooster () {
    HBAKBoosterAudioUnit *_internalAU;
    AUParameter *_leftGainParameter;
    AUParameter *_rightGainParameter;
    
    double _lastKnownLeftGain;
    double _lastKnownRightGain;
}

@end

@implementation HBAKBooster

- (instancetype)initWithNode:(HBAKNode *)input gain:(double)gain {
    self = [super init];
    if (self) {
        self.leftGain = gain;
        self.rightGain = gain;
        
        self.rampDuration = HBAKSettings.rampDuration;
        self.rampType = 0;
        
        static AudioComponentDescription componentDescription;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            componentDescription.componentType = kAudioUnitType_Effect;
            componentDescription.componentSubType = 'bstr';
            componentDescription.componentManufacturer = 'AuKt';
            componentDescription.componentFlags = kAudioComponentFlag_SandboxSafe;
            componentDescription.componentFlagsMask = 0;
        });
        
        [AUAudioUnit registerSubclass:HBAKBoosterAudioUnit.class asComponentDescription:componentDescription name:@"Local HBAKBooster" version:UINT_MAX];
        
        [AVAudioUnit instantiateWithComponentDescription:componentDescription options:0 completionHandler:^(__kindof AVAudioUnit * _Nullable audioUnit, NSError * _Nullable error) {
            if (audioUnit) {
                [HBAudioKit.engine attachNode:audioUnit];
                
                self.avAudioUnit = audioUnit;
                self.avAudioNode = audioUnit;
                self->_internalAU = (HBAKBoosterAudioUnit *)audioUnit.AUAudioUnit;
                
                [input connectToNode:self];
            }
        }];
        
        if (!_internalAU.parameterTree) {
            NSLog(@"Parameter Tree Failed");
        }
        
        _leftGainParameter = [[_internalAU.parameterTree allParameters] hb_filterElements:^BOOL(AUParameter * _Nonnull elemtent) {
            return [elemtent.identifier isEqualToString:@"leftGain"];
        }].firstObject;
        
        _rightGainParameter = [[_internalAU.parameterTree allParameters] hb_filterElements:^BOOL(AUParameter * _Nonnull elemtent) {
            return [elemtent.identifier isEqualToString:@"rightGain"];
        }].firstObject;
        
        [_internalAU setParameterImmediately:HBAKBoosterParameterLeftGain value:gain];
        [_internalAU setParameterImmediately:HBAKBoosterParameterRightGain value:gain];
        [_internalAU setParameterImmediately:HBAKBoosterParameterRampDuration value:self.rampDuration];
        _internalAU.rampType = self.rampType;
    }
    return self;
}

- (void)setRampDuration:(double)rampDuration {
    _rampDuration = rampDuration;
    
    _internalAU.rampDuration = rampDuration;
}

- (void)setRampType:(double)rampType {
    _rampType = rampType;
    
    _internalAU.rampType = rampType;
}

- (void)setGain:(double)gain {
    if (_gain != gain) {
        _gain = gain;
        if (_internalAU.isSetUp) {
            _leftGainParameter.value = gain;
            _rightGainParameter.value = gain;
            return;
        }
        
        [_internalAU setParameterImmediately:HBAKBoosterParameterLeftGain value:gain];
        [_internalAU setParameterImmediately:HBAKBoosterParameterRightGain value:gain];
    }
}

- (void)setLeftGain:(double)leftGain {
    if (_leftGain != leftGain) {
        _leftGain = leftGain;
        
        if (_internalAU.isSetUp) {
            _leftGainParameter.value = leftGain;
            
            return;
        }
        [_internalAU setParameterImmediately:HBAKBoosterParameterLeftGain value:leftGain];
    }
}

- (void)setRightGain:(double)rightGain {
    if (_rightGain != rightGain) {
        _rightGain = rightGain;
        
        if (_internalAU.isSetUp) {
            _rightGainParameter.value = rightGain;
            return;
        }
        
        [_internalAU setParameterImmediately:HBAKBoosterParameterRightGain value:rightGain];
    }
}

- (void)setDB:(double)dB {
    self.gain = pow(10, dB/20.0);
}

- (double)dB {
    return 20*log10(self.gain);
}

- (BOOL)isStarted {
    return _internalAU.isPlaying;
}

- (void)start {
    if ([self isStopped]) {
        self.leftGain = _lastKnownLeftGain;
        self.rightGain = _lastKnownRightGain;
    }
}

- (void)stop {
    if ([self isPlaying]) {
        _lastKnownLeftGain = self.leftGain;
        _lastKnownRightGain = self.rightGain;
        
        self.leftGain = 1;
        self.rightGain = 1;
    }
}

@end
