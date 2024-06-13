//
//  HBAKMicrophone.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKMicrophone.h"
#import "HBAKSettings.h"
#import "HBAudioKit.h"

@interface HBAKMicrophone () {
    AVAudioMixerNode *_mixer;
    
    double _lastKnownVolume;
}

@end

@implementation HBAKMicrophone

- (instancetype)init {
    self = [super init];
    if (self) {
        _mixer = [AVAudioMixerNode new];
    }
    return self;
}

- (instancetype)initWithFormat:(AVAudioFormat *)format {
    self = [self init];
    if (self) {
        self.avAudioNode = _mixer;
        HBAKSettings.audioInputEnabled = YES;
        
        AVAudioFormat *finalFormat = format;
        if (!finalFormat) {
            finalFormat = [self getFormatForDevice];
        }
        
        [HBAudioKit.engine attachNode:self.avAudioUnitOrNode];
        [HBAudioKit.engine connect:HBAudioKit.engine.inputNode to:self.avAudioNode format:format];
    }
    return self;
}

- (void)setVolume:(double)volume {
    _volume = MAX(volume, 0);
    _mixer.outputVolume = _volume;
}

- (void)setDevice:(HBAKDevice *)device {
    [HBAudioKit setInputDevice:device];
}

- (void)setAVAseesionSampleRate:(double)sampleRate {
    [[AVAudioSession sharedInstance] setPreferredSampleRate:sampleRate error:nil];
}

- (BOOL)isStarted {
    return _volume != 0.0;
}

- (void)start {
    if ([self isStarted]) {
        self.volume = _lastKnownVolume;
    }
}

- (void)stop {
    if ([self isPlaying]) {
        _lastKnownVolume = _volume;
        self.volume = 0;
    }
}

- (AVAudioFormat *)getFormatForDevice {
    AVAudioFormat *audioFormat = nil;
    AVAudioFormat *currentFormat = [HBAudioKit.engine.inputNode inputFormatForBus:0];
    double sampleRate = [AVAudioSession sharedInstance].sampleRate;
    double desiredFS = (sampleRate == currentFormat.sampleRate)?sampleRate:currentFormat.sampleRate;
    if (currentFormat.channelLayout) {
        audioFormat = [[AVAudioFormat alloc] initWithCommonFormat:currentFormat.commonFormat
                                                       sampleRate:desiredFS
                                                      interleaved:currentFormat.isInterleaved
                                                    channelLayout:currentFormat.channelLayout];
    } else {
        audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:desiredFS channels:2];
    }
    return audioFormat;
}

@end
