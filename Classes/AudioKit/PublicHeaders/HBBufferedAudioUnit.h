//
//  HBBufferedAudioUnit.h
//  ProtonCrew
//
//  Created by R_style_Man on 2021/12/5.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

/** No Swift or ObjC functions and property access. No ARC managed references/assignments. */
typedef void(^ProcessEventsBlock)(AudioBufferList        * _Nullable inBuffer,
                                  AudioBufferList        * _Nonnull  outBuffer,
                                  const AudioTimeStamp   * _Nonnull  timestamp,
                                  AVAudioFrameCount                  frameCount,
                                  const AURenderEvent    * _Nullable eventsListHead);

@interface HBBufferedAudioUnit : AUAudioUnit

/** Subclasses should overide this to return a block to do processing in. */
-(ProcessEventsBlock)processEventsBlock:(AVAudioFormat *)format;

/** If true, an input bus will be allocated, intended for subclasses to override, defaults to true. */
-(BOOL)shouldAllocateInputBus;

/** If true, the output buffer samples will be set to zero pre-render, Intended for subclasses to override, defaults to false */
-(BOOL)shouldClearOutputBuffer;


@end

NS_ASSUME_NONNULL_END
