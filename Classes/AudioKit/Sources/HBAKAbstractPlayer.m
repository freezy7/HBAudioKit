//
//  HBAKAbstractPlayer.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/6.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKAbstractPlayer.h"

@implementation HBAKLoop

- (instancetype)init {
    self = [super init];
    if (self) {
        _start = 0;
        _end = 0;
    }
    return self;
}

- (void)setStart:(double)start {
    if (_start != start) {
        _start = start;
        _needsUpdate = YES;
    }
}

- (void)setEnd:(double)end {
    if (_end != end) {
        _end = end;
        _needsUpdate = YES;
    }
}

@end

@interface HBAKAbstractPlayer () {
    HBAKLoop *_innerLoop;
}

@end

@implementation HBAKAbstractPlayer

- (HBAKLoop *)loop {
    if (!_innerLoop) {
        _innerLoop = [HBAKLoop new];
    }
    return _innerLoop;
}

- (void)setStartTime:(double)startTime {
    _startTime = MAX(0, startTime);
}

- (void)setEndTime:(double)endTime {
    _endTime = MIN(endTime, self.duration);
}

- (double)sampleRate {
    return HBAKSettings.sampleRate;
}

- (HBAKPlayerRenderingMode)renderingMode {
    if (self.outputNode.engine.manualRenderingMode == AVAudioEngineManualRenderingModeOffline) {
        return HBAKPlayerRenderingModeOffline;
    }
    return HBAKPlayerRenderingModeRealTime;
}

- (void)initializeRestartIfPlaying:(BOOL)restartIfPlaying {
    
}

- (void)play {
    
}

- (void)stop {
    
}

- (void)detach {
    
}

@end
