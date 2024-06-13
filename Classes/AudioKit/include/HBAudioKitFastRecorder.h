//
//  HBAudioKitFastRecorder.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2020/4/23.
//  Copyright © 2020 ProtonCrew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "HBAudioKit.h"
#import "HBAKPlayer.h"
#import "HBAKMixer.h"
#import "HBAKMicrophone.h"

typedef void(^RecorderProcessingCallback)(float lVol, unsigned long currentLength, unsigned long totalLength);

NS_ASSUME_NONNULL_BEGIN

/// 用于群聊语音音频和对话小说中的音频
@interface HBAudioKitFastRecorder : NSObject

/// 麦克风
@property (nonatomic, strong) HBAKMicrophone *mic;
@property (nonatomic, strong, readonly) NSString *savePath;

- (void)startRecordWithProcessingCallback:(RecorderProcessingCallback)processingCallback;

/// 停止所有录制操作
- (void)stopRecorderOperationCompletion:(nullable void(^)(void))completion;

- (void)exchangePCMToMP3Completion:(void(^)(BOOL success, NSString *outputPath))completion;

/// 将录制的音频文件转换为MP3格式
+ (void)exchangePCMToMP3WithFilePath:(NSString *)filePath resultPath:(NSString *)resultPath completion:(void(^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
