//
//  HBAKPlayer.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/6.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKPlayer.h"
#import "HBAudioKit.h"

@interface HBAKPlayer () {
    AVAudioFramePosition _startingFrame;
    AVAudioFramePosition _endingFrame;
}

@end

@implementation HBAKPlayer

- (instancetype)init {
    AVAudioPlayerNode *playerNode = [AVAudioPlayerNode new];
    AVAudioMixerNode *mixer = [AVAudioMixerNode new];
    self = [super initWithAvAudioNode:mixer attach:false];
    if (self) {
        _playerNode = playerNode;
        _mixer = mixer;
    }
    return self;
}

// 播放器持续播放的时间
- (double)playerTime {
    AVAudioTime *nodeTime = _playerNode.lastRenderTime;
    if (nodeTime && (nodeTime.sampleTimeValid || nodeTime.hostTimeValid)) {
        AVAudioTime *playerTime = [_playerNode playerTimeForNodeTime:nodeTime];
        if (playerTime) {
            return playerTime.sampleTime/playerTime.sampleRate;
        }
    }
    return 0;
}

- (HBAKPlayerRenderingMode)renderingMode {
    if (self.playerNode.engine.manualRenderingMode == AVAudioEngineManualRenderingModeOffline) {
        return HBAKPlayerRenderingModeOffline;
    }
    return HBAKPlayerRenderingModeRealTime;
}

- (double)duration {
    if (_audioFile) {
        return _audioFile.length/_audioFile.fileFormat.sampleRate;
    }
    return 0;
}

- (double)sampleRate {
    return [_playerNode outputFormatForBus:0].sampleRate;
}

- (void)setVolume:(double)volume {
    _playerNode.volume = volume;
}

- (double)volume {
    return _playerNode.volume;
}

- (void)setPan:(double)pan {
    _playerNode.pan = pan;
}

- (double)pan {
    return _playerNode.pan;
}

- (AVAudioFramePosition)currentFrame {
    AVAudioTime *nodeTime = _playerNode.lastRenderTime;
    if (nodeTime && (nodeTime.sampleTimeValid || nodeTime.hostTimeValid)) {
        AVAudioTime *playerTime = [_playerNode playerTimeForNodeTime:nodeTime];
        if (playerTime) {
            return playerTime.sampleTime;
        }
    }
    return 0;
}

- (double)currentTime {
    double currentDuration = (self.endTime - self.startTime == 0)?self.duration:(self.endTime - self.startTime);
    double normalizedPauseTime = 0.0;
    if (self.pauseTime > self.startTime) {
        normalizedPauseTime = _pauseTime - self.startTime;
    }
    
    // 对浮点数取余数
    NSInteger currentDurationInt = currentDuration * 1000;
    NSInteger playerTimeInt = [self playerTime] * 1000;
    
    double current = self.startTime + normalizedPauseTime + (playerTimeInt % currentDurationInt)/1000.f;
    return current;
}

- (void)setPauseTime:(double)pauseTime {
    _pauseTime = pauseTime;
    
    _isPaused = pauseTime > 0;
}

- (AVAudioFormat *)processingFormat {
    return _audioFile.processingFormat;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        return nil;
    }
    NSError *error = nil;
    AVAudioFile *avfile = [[AVAudioFile alloc] initForReading:url error:&error];
    if (avfile && !error) {
        return [self initWithAudioFile:avfile reopenFile:false];
    }
    return nil;
}

- (instancetype)initWithAudioFile:(AVAudioFile *)audioFile reopenFile:(BOOL)reopenFile {
    self = [self init];
    
    self.audioFile = audioFile;
    if (reopenFile) {
        NSError *error = nil;
        AVAudioFile *readFile = [[AVAudioFile alloc] initForReading:audioFile.url error:&error];
        if (readFile && !error) {
            self.audioFile = readFile;
        }
    }
    
    [self initializeRestartIfPlaying:false];
    
    return self;
}

- (void)initializeRestartIfPlaying:(BOOL)restartIfPlaying {
    BOOL wasPlaying = [self isPlaying] && restartIfPlaying;
    if (wasPlaying) {
        [self pause];
    }
    
    if (!_mixer.engine) {
        [HBAudioKit.engine attachNode:_mixer];
    }
    
    if (!_playerNode.engine) {
        [HBAudioKit.engine attachNode:_playerNode];
    } else {
        [HBAudioKit.engine disconnectNodeOutput:_playerNode];
    }
    
    self.loop.start = 0;
    self.loop.end = self.duration;
    
    [self connectNodes];
    if (wasPlaying) {
        [self resume];
    }
}

- (void)connectNodes {
    if (![self processingFormat]) {
        return;
    }
    
    [HBAudioKit connectNode1:self.playerNode toNode2:self.mixer fromBus1:0 toBus2:0 format:self.processingFormat];
}

- (void)loadURL:(NSURL *)url {
    NSError *error = nil;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:url error:&error];
    if (file && !error) {
        [self loadAudioFile:file];
    }
}

- (void)loadAudioFile:(AVAudioFile *)audioFile {
    self.audioFile = audioFile;
    
    [self initializeRestartIfPlaying:false];
    [self prerollFromStartingTime:0 toEndingTime:0];
}

- (void)prerollFromStartingTime:(double)startingTime toEndingTime:(double)endingTime {
    double from = startingTime;
    double to = endingTime;
    
    if (to == 0) {
        to =  self.duration;
    }
    if (from > to) {
        from = 0;
    }
    
    self.startTime = from;
    self.endTime = to;
}

- (void)play {
    [self playFromStartingTime:self.startTime toEndingTime:self.endTime atAudioTime:nil hostTime:0];
}

- (void)playFromStartingTime:(double)startingTime toEndingTime:(double)endingTime atAudioTime:(AVAudioTime *)audioTime hostTime:(UInt64)hostTime {
    // fix player did not see an IO cycle
    if (!self.playerNode.engine.isRunning) {
        return;
    }
    
    UInt64 refTime = hostTime>0?hostTime:CACurrentMediaTime();
    AVAudioTime *tAudioTime = audioTime?audioTime:[[AVAudioTime alloc] initWithHostTime:CACurrentMediaTime()];
    
    
    
    [self prerollFromStartingTime:startingTime toEndingTime:endingTime];
    [self schedulePlayerAtAudioTime:tAudioTime hostTime:refTime];
    
    if (self.playerNode.engine.isRunning) {
        self.isPlaying = YES;
        [self.playerNode play];
        self.pauseTime = 0;
    }
}

- (void)stop {
    [self stopCompletion];
}

- (void)detach {
    [self stop];
    
    [super detach];
    
    _audioFile = nil;
    [HBAudioKit.engine detachNode:_mixer];
    [HBAudioKit.engine detachNode:_playerNode];
}

#pragma mark - AKTiming

- (void)startAtAudioTime:(AVAudioTime *)audioTime {
    [self playAtAudioTime:audioTime];
}

- (BOOL)isStarted {
    return self.isPlaying;
}

- (void)setPosition:(double)position {
    self.startTime = position;
    if ([self isPlaying]) {
        [self stop];
        [self play];
    }
}

- (double)positionAtAudioTime:(AVAudioTime *)audioTime {
    AVAudioTime *tAudioTime = audioTime?audioTime:[[AVAudioTime alloc] initWithHostTime:CACurrentMediaTime()];
    AVAudioTime *playerTime = [_playerNode playerTimeForNodeTime:tAudioTime];
    if (playerTime) {
        return self.startTime + playerTime.sampleTime/playerTime.sampleRate;
    }
    return self.startTime;
}

- (AVAudioTime *)audioTimeAtPosition:(double)position {
    double sampleRate = [_playerNode outputFormatForBus:0].sampleRate;
    double sampleTime = (position - self.startTime) * sampleRate;
    AVAudioTime *playerTime = [[AVAudioTime alloc] initWithSampleTime:sampleTime atRate:sampleRate];
    return [_playerNode nodeTimeForPlayerTime:playerTime];
}

- (void)prepare {
    [self prerollFromStartingTime:self.startTime toEndingTime:self.endTime];
}

#pragma mark - Playback

- (BOOL)useCompletionHandler {
    return (self.isLooping) || (self.completionHandler != nil);
}

- (void)playFromStartingTime:(double)startingTime toEndingTime:(double)endingTime {
    double to = endingTime;
    if (to == 0) {
        to = self.endTime;
    }
    [self playFromStartingTime:startingTime toEndingTime:to atAudioTime:nil hostTime:0];
}

- (void)playAtAudioTime:(AVAudioTime *)audioTime {
    if (audioTime) {
        if (audioTime.isHostTimeValid && audioTime.hostTime < CACurrentMediaTime()) {
            [self playAtAudioTime:nil hostTime:0];
        } else {
            [self playAtAudioTime:audioTime hostTime:0];
        }
    }
}

- (void)playAtAudioTime:(nullable AVAudioTime *)audioTime hostTime:(UInt64)hostTime {
    [self playFromStartingTime:self.startTime toEndingTime:self.endTime atAudioTime:audioTime hostTime:hostTime];
}

- (void)playWhenScheduledTime:(double)scheduledTime hostTime:(UInt64)hostTime {
    [self playFromStartingTime:self.startTime toEndingTime:self.endTime whenScheduledTime:scheduledTime hostTime:hostTime];
}

- (void)playFromStartingTime:(double)startingTime toEndingTime:(double)endingTime whenScheduledTime:(double)scheduledTime hostTime:(UInt64)hostTime {
    UInt64 refTime = hostTime>0?hostTime:CACurrentMediaTime();
    AVAudioTime *avTime = nil;
    if (self.renderingMode == HBAKPlayerRenderingModeOffline) {
        double sampleTime = scheduledTime * self.sampleRate;
        AVAudioTime *sampleAVTime = [[AVAudioTime alloc] initWithHostTime:refTime sampleTime:sampleTime atRate:self.sampleRate];
        avTime = sampleAVTime;
    } else {
        double ticksToSeconds = [AVAudioTime hostTimeForSeconds:scheduledTime];
        
        AVAudioTime *tempAudioTime = [[AVAudioTime alloc] initWithHostTime:refTime];
        if (tempAudioTime.isSampleTimeValid && tempAudioTime.isHostTimeValid) {
            avTime = [[AVAudioTime alloc] initWithHostTime:tempAudioTime.hostTime + ticksToSeconds
                                                sampleTime:tempAudioTime.sampleTime + scheduledTime * tempAudioTime.sampleRate
                                                    atRate:tempAudioTime.sampleRate];
        } else if (tempAudioTime.isHostTimeValid) {
            avTime = [[AVAudioTime alloc] initWithHostTime:tempAudioTime.hostTime + ticksToSeconds];
        } else if (tempAudioTime.isSampleTimeValid) {
            avTime = [[AVAudioTime alloc] initWithSampleTime:tempAudioTime.sampleTime + scheduledTime * tempAudioTime.sampleRate
                                                      atRate:tempAudioTime.sampleRate];
        } else {
            avTime = tempAudioTime;
        }
    }
    
    [self playFromStartingTime:startingTime toEndingTime:endingTime atAudioTime:avTime hostTime:refTime];
}

- (void)pause {
    _pauseTime = [self currentTime];
    [self stop];
}

- (void)resume {
    double previousStartTime = self.startTime;
    double time = _pauseTime>0?_pauseTime:0;
    
    if (time > self.duration) {
        time = 0;
    }
    
    [_playerNode stop];
    [self playFromStartingTime:time toEndingTime:0];
    
    self.startTime = previousStartTime;
    self.pauseTime = time;
    _isPaused = NO;
}

- (void)stopCompletion {
    [_playerNode stop];
    self.isPlaying = NO;
}

- (void)schedulePlayerAtAudioTime:(AVAudioTime *)audioTime hostTime:(UInt64)hostTime {
    //  UInt64 refTime = hostTime>0?hostTime:CACurrentMediaTime();
    [self scheduleSegmentAtAudioTime:audioTime];
}

// play from disk rather than ram
- (void)scheduleSegmentAtAudioTime:(AVAudioTime *)audioTime {
    if (!self.audioFile) {
        return;
    }
    
    AVAudioFramePosition startFrame = (AVAudioFramePosition)(self.startTime * self.audioFile.fileFormat.sampleRate);
    AVAudioFramePosition endFrame = (AVAudioFramePosition)(self.endTime * self.audioFile.fileFormat.sampleRate);
    
    if (endFrame == 0) {
        endFrame = self.audioFile.length;
    }
    
    AVAudioFramePosition totalFrames = (self.audioFile.length - startFrame) - (self.audioFile.length - endFrame);
    if (totalFrames <= 0) {
        NSLog(@"Unable to schedule file. totalFrames to play is %lld. audioFile.length is \(%lld)", totalFrames, self.audioFile.length);
        return;
    }
    
    self.frameCount = (AVAudioFrameCount)totalFrames;
    
    __weak __typeof(&*self)weakSelf = self;
    [_playerNode scheduleSegment:self.audioFile
                   startingFrame:startFrame
                      frameCount:self.frameCount
                          atTime:audioTime
          completionCallbackType:AVAudioPlayerNodeCompletionDataRendered
               completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
        [weakSelf handleCallbackComplete:callbackType];
    }];
    
    [_playerNode prepareWithFrameCount:self.frameCount];
}

- (void)handleCallbackComplete:(AVAudioPlayerNodeCompletionCallbackType)completionType {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentFrame > 0) {
            [self handleComplete];
        }
    });
}

- (void)handleComplete {
    [self stop];
    if (self.isLooping) {
        self.startTime = self.loop.start;
        self.endTime = self.loop.end;
        [self play];
        if (self.loopCompletionHandler) {
            self.loopCompletionHandler();
        }
        return;
    }
    if (_pauseTime != 0) {
        self.startTime = 0;
        _pauseTime = 0;
    }
    
    if (self.completionHandler) {
        self.completionHandler();
    }
}

@end
