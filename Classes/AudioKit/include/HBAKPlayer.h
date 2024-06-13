//
//  HBAKPlayer.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/6.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKAbstractPlayer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HBAKPlayerBufferingType) {
  HBAKPlayerBufferingTypeDynamic,
  HBAKPlayerBufferingTypeAlways,
};

typedef void(^HBAKCallback)(void);

@interface HBAKPlayer : HBAKAbstractPlayer

@property (nonatomic, strong) AVAudioPlayerNode *playerNode;
@property (nonatomic, strong) AVAudioMixerNode *mixer;

@property (nonatomic, copy) HBAKCallback completionHandler;
@property (nonatomic, copy) HBAKCallback loopCompletionHandler;


@property (nonatomic, strong) AVAudioFile *audioFile;

@property (nonatomic) double volume;
@property (nonatomic) double pan;

@property (nonatomic) AVAudioFrameCount frameCount;
@property (nonatomic, readonly) AVAudioFramePosition currentFrame;
@property (nonatomic, readonly) double currentTime;

@property (nonatomic) double pauseTime;

@property (nonatomic, strong, readonly) AVAudioFormat *processingFormat;

@property (nonatomic) BOOL isPaused;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithAudioFile:(AVAudioFile *)audioFile reopenFile:(BOOL)reopenFile;

- (void)loadURL:(NSURL *)url;
- (void)loadAudioFile:(AVAudioFile *)audioFile;

- (void)prerollFromStartingTime:(double)startingTime toEndingTime:(double)endingTime;

- (void)play;
- (void)playFromStartingTime:(double)startingTime toEndingTime:(double)endingTime atAudioTime:(nullable AVAudioTime *)audioTime hostTime:(UInt64)hostTime;

- (void)stop;
- (void)detach;

- (void)startAtAudioTime:(AVAudioTime *)audioTime;
- (BOOL)isStarted;

- (void)setPosition:(double)position;
- (double)positionAtAudioTime:(AVAudioTime *)audioTime;
- (AVAudioTime *)audioTimeAtPosition:(double)position;
- (void)prepare;

#pragma mark - Playback

- (void)playFromStartingTime:(double)startingTime toEndingTime:(double)endingTime;
- (void)playAtAudioTime:(AVAudioTime *)audioTime;
- (void)playAtAudioTime:(nullable AVAudioTime *)audioTime hostTime:(UInt64)hostTime;

- (void)playWhenScheduledTime:(double)scheduledTime hostTime:(UInt64)hostTime;
- (void)playFromStartingTime:(double)startingTime toEndingTime:(double)endingTime whenScheduledTime:(double)scheduledTime hostTime:(UInt64)hostTime;

- (void)pause;
- (void)resume;

- (void)stopCompletion;

- (void)schedulePlayerAtAudioTime:(AVAudioTime *)audioTime hostTime:(UInt64)hostTime;
- (void)scheduleSegmentAtAudioTime:(AVAudioTime *)audioTime;

- (void)handleCallbackComplete:(AVAudioPlayerNodeCompletionCallbackType)completionType;
- (void)handleComplete;

@end

NS_ASSUME_NONNULL_END
