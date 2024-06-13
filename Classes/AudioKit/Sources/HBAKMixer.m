//
//  HBAKMixer.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKMixer.h"

@interface HBAKMixer () {
    AVAudioMixerNode *_mixerAU;
    
    double _lastKnownVolume;
}

@end

@implementation HBAKMixer

- (instancetype)init {
    AVAudioMixerNode *mixerAU = [AVAudioMixerNode new];
    self = [super initWithAvAudioNode:mixerAU attach:YES];
    if (self) {
        _mixerAU = mixerAU;
        _lastKnownVolume = 1.0f;
    }
    return self;
}

- (instancetype)initWithInputs:(NSArray<HBAKNode *> *)inputs {
    self = [self init];
    if (self) {
        for (HBAKNode *input in inputs) {
            [input connectToNode:self];
        }
    }
    return self;
}

- (void)setVolume:(double)volume {
    _volume = MAX(volume, 0);
    _mixerAU.outputVolume = volume;
}

- (BOOL)isStarted {
    return _volume != 0.0;;
}

- (void)start {
    if ([self isStopped]) {
        _volume = _lastKnownVolume;
    }
}

- (void)stop {
    if ([self isPlaying]) {
        _lastKnownVolume = _volume;
        _volume = 0;
    }
}

- (void)detach {
    [super detach];
}

@end
