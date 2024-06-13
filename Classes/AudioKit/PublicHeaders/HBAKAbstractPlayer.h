//
//  HBAKAbstractPlayer.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/6.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKNode.h"
#import "HBAKSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBAKLoop : NSObject

@property (nonatomic) double start;
@property (nonatomic) double end;

@property (nonatomic) BOOL needsUpdate;

@end

typedef NS_ENUM(NSUInteger, HBAKPlayerRenderingMode) {
  HBAKPlayerRenderingModeRealTime,
  HBAKPlayerRenderingModeOffline,
};

@interface HBAKAbstractPlayer : HBAKNode {
  AVAudioFramePosition _startingFrame;
  AVAudioFramePosition _endingFrame;
}

@property (nonatomic, readonly) HBAKPlayerRenderingMode renderingMode;

@property (nonatomic, strong) HBAKLoop *loop;

@property (nonatomic) double gain;

@property (nonatomic) double startTime;
@property (nonatomic) double endTime;

@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL isLooping;

@property (nonatomic, readonly) double duration;
@property (nonatomic) double sampleRate;

- (void)initializeRestartIfPlaying:(BOOL)restartIfPlaying;

- (void)play;
- (void)stop;
- (void)detach;

@end

NS_ASSUME_NONNULL_END
