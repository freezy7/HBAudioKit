//
//  HBAKSettings.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKSettings.h"
#import "HBAudioSession.h"

@implementation HBAKSettings

static BOOL _innerAudioInputEnabled = NO;
+ (void)setAudioInputEnabled:(BOOL)audioInputEnabled {
    _innerAudioInputEnabled = audioInputEnabled;
}

+ (BOOL)audioInputEnabled {
    return _innerAudioInputEnabled;
}

static BOOL _innerPlaybackWhileMuted = NO;
+ (void)setPlaybackWhileMuted:(BOOL)playbackWhileMuted {
    _innerPlaybackWhileMuted = playbackWhileMuted;
}

+ (BOOL)playbackWhileMuted {
    return _innerPlaybackWhileMuted;
}

static BOOL _innerDefaultToSpeaker = NO;
+ (void)setDefaultToSpeaker:(BOOL)defaultToSpeaker {
    _innerDefaultToSpeaker = defaultToSpeaker;
}

+ (BOOL)defaultToSpeaker {
    return _innerDefaultToSpeaker;
}


static BOOL _innerUseBluetooth = NO;
+ (void)setUseBluetooth:(BOOL)useBluetooth {
    _innerUseBluetooth = useBluetooth;
}

+ (BOOL)useBluetooth {
    return _innerUseBluetooth;
}

static BOOL _innerAllowAirPlay = NO;
+ (void)setAllowAirPlay:(BOOL)allowAirPlay {
    _innerAllowAirPlay = allowAirPlay;
}

+ (BOOL)allowAirPlay {
    return _innerAllowAirPlay;
}

static AVAudioSessionCategoryOptions _innerBluetoothOptions = 0;
+ (void)setBluetoothOptions:(AVAudioSessionCategoryOptions)bluetoothOptions {
    _innerBluetoothOptions = bluetoothOptions;
}

+ (AVAudioSessionCategoryOptions)bluetoothOptions {
    return _innerBluetoothOptions;
}

static BOOL _innerenableEchoCancellation = NO;
+ (void)setEnableEchoCancellation:(BOOL)enableEchoCancellation {
    _innerenableEchoCancellation = enableEchoCancellation;
}

+ (BOOL)enableEchoCancellation {
    return _innerenableEchoCancellation;
}

static BOOL _innerdisableAVAudioSessionCategoryManagement = NO;
+ (void)setDisableAVAudioSessionCategoryManagement:(BOOL)disableAVAudioSessionCategoryManagement {
    _innerdisableAVAudioSessionCategoryManagement = disableAVAudioSessionCategoryManagement;
}

+ (BOOL)disableAVAudioSessionCategoryManagement {
    return _innerdisableAVAudioSessionCategoryManagement;
}

+ (double)rampDuration {
    return 0.0002;
}

+ (double)sampleRate {
    return 44100;
}

+ (UInt32)channelCount {
    return 2;
}

+ (AVAudioFormat *)audioFormat {
    return [[AVAudioFormat alloc] initStandardFormatWithSampleRate:self.sampleRate channels:self.channelCount];
}

+ (void)setSessionCategory:(AVAudioSessionCategory)sessionCategory options:(AVAudioSessionCategoryOptions)options error:(NSError **)error {
    [[AVAudioSession sharedInstance] setCategory:sessionCategory withOptions:options error:error];
    if (error) {
        return;
    }
    
    if (@available(iOS 13.0, *)) {
        [[AVAudioSession sharedInstance] setAllowHapticsAndSystemSoundsDuringRecording:NO error:error];
        if (error) {
            return;
        }
    }
    
    // 选择时长等级的级别
    AVAudioFrameCount sampleCount = (AVAudioFrameCount)pow(2.0, 8.0);
    double bufferDuration = sampleCount/[self sampleRate];
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:bufferDuration error:error];
    
    if (error) {
        return;
    }
    
    [[HBAudioSession sharedSession] setActive:YES];
}

+ (AVAudioSessionCategory)computedSessionCategory {
    if ([self audioInputEnabled]) {
        return AVAudioSessionCategoryPlayAndRecord;
    } else if ([self playbackWhileMuted]) {
        return AVAudioSessionCategoryPlayback;
    } else {
        return AVAudioSessionCategoryAmbient;
    }
}

+ (AVAudioSessionCategoryOptions)computedSessionOptions {
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionMixWithOthers;
    if ([self audioInputEnabled]) {
        if ([self bluetoothOptions] > 0) {
            options = options|[self audioInputEnabled];
        } else if ([self useBluetooth]) {
            options = options|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP;
        }
        
        if ([self allowAirPlay]) {
            options = options|AVAudioSessionCategoryOptionAllowAirPlay;
        }
        
        if ([self defaultToSpeaker]) {
            options = options|AVAudioSessionCategoryOptionDefaultToSpeaker;
        }
    }
    
    return options;
}

+ (BOOL)headPhonesPlugged {
    for (AVAudioSessionPortDescription * _Nonnull elemtent in [AVAudioSession sharedInstance].currentRoute.outputs) {
        if ([elemtent.portType isEqualToString:AVAudioSessionPortHeadphones] ||
            [elemtent.portType isEqualToString:AVAudioSessionPortBluetoothHFP] ||
            [elemtent.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            return YES;
        }
    }
    return NO;
}

@end
