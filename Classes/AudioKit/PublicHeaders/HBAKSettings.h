//
//  HBAKSettings.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HBAKRampType) {
  HBAKRampTypeLinear = 0,
  HBAKRampTypeExponential = 1,
  HBAKRampTypeLogarithmic = 2,
  HBAKRampTypeSCure = 3
};

@interface HBAKSettings : NSObject

@property (nonatomic, class) BOOL audioInputEnabled;
@property (nonatomic, class) BOOL playbackWhileMuted;

@property (nonatomic, class) BOOL defaultToSpeaker;
@property (nonatomic, class) BOOL useBluetooth;
@property (nonatomic, class) BOOL allowAirPlay;
@property (nonatomic, class) AVAudioSessionCategoryOptions bluetoothOptions;

@property (nonatomic, class) BOOL enableEchoCancellation;

@property (nonatomic, class) BOOL disableAVAudioSessionCategoryManagement;

@property (nonatomic, class, readonly) double rampDuration;

@property (nonatomic, class, readonly) double sampleRate;
@property (nonatomic, class, readonly) UInt32 channelCount;

@property (nonatomic, class, readonly) AVAudioFormat *audioFormat;

+ (void)setSessionCategory:(AVAudioSessionCategory)sessionCategory options:(AVAudioSessionCategoryOptions)options error:(NSError **)error;
+ (AVAudioSessionCategory)computedSessionCategory;
+ (AVAudioSessionCategoryOptions)computedSessionOptions;
+ (BOOL)headPhonesPlugged;

@end

NS_ASSUME_NONNULL_END
