//
//  HBAudioKitFastRecorder.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2020/4/23.
//  Copyright © 2020 ProtonCrew. All rights reserved.
//

#import "HBAudioKitFastRecorder.h"
#import "HBAudioSession.h"
#import "HBAKSettings.h"
#import "HBAKBooster.h"
#import <lame/lame.h>

typedef NS_ENUM(NSUInteger, HBRecorderDeviceState) {
  HBRecorderDeviceStateUnknown,
  HBRecorderDeviceStateSpeacker,  // 未插耳机
  HBRecorderDeviceStateHeadPhones,// 插耳机
};

@interface HBAudioKitFastRecorder ()

@property (nonatomic, strong) HBAKBooster *micBooster;
@property (nonatomic, strong) HBAKMixer *micMixer;

@property (nonatomic, strong) NSString *savePath;
@property (nonatomic, strong) AVAudioFile *saveAudioFile;

@property (nonatomic) NSInteger bus;
@property (nonatomic) double recordBufferDuration;

@property (nonatomic, weak) AVAudioNode *innerSaveMixNode;

@property (nonatomic) AVAudioFrameCount totalRecordBufferFrameLength;

@property (nonatomic) HBRecorderDeviceState deviceState;

@property (nonatomic, strong) RecorderProcessingCallback processingCallback;

@end

@implementation HBAudioKitFastRecorder

+ (NSString *)getDocumentRootPath {
  NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  return paths.firstObject;
}

+ (NSString *)getDocumentPathWithDir:(NSString *)dir {
  NSString *docDir = [[self getDocumentRootPath] stringByAppendingPathComponent:dir];
  if (![[NSFileManager defaultManager] fileExistsAtPath:docDir]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:docDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
  }
  return docDir;
}

+ (NSString *)getDocumentPathWithDir:(NSString *)dir fileName:(NSString *)fileName {
  return [[self getDocumentPathWithDir:dir] stringByAppendingPathComponent:fileName];
}


- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  NSLog(@"HBAudioKitFastRecorder ------ dealloc -------");
  NSError *error = nil;
  [HBAudioKit disconnectAllInputs];
  [HBAudioKit stopAndReturnError:&error];
  [HBAudioKit shutdownAndReturnError:&error];
  
  if (error) {
    NSLog(@"Record stop Error: %@", error);
  }
  
  if (HBAudioKit.engine.isRunning) {
    
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.savePath = [HBAudioKitFastRecorder getDocumentPathWithDir:@"audioRecord/temp" fileName:@"audio.pcm"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    
    [self setupMainMixer];
  }
  return self;
}

- (void)setupMainMixer {
  
  // Session setting
  HBRecorderDeviceState deviceState = HBAKSettings.headPhonesPlugged?HBRecorderDeviceStateHeadPhones:HBRecorderDeviceStateSpeacker;
  if (self.deviceState != deviceState) {
    self.deviceState = deviceState;
  }
  
  HBAKSettings.audioInputEnabled = true;
  HBAKSettings.useBluetooth = true;
  
  if (HBAKSettings.headPhonesPlugged) {
    // 头戴耳机不需要输出到手机扬声器，直接输出耳机的扬声器就行
    HBAKSettings.defaultToSpeaker = false;
    HBAKSettings.disableAVAudioSessionCategoryManagement = false;
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    
    [[HBAudioSession sharedSession] setActive:YES];
    NSLog(@"session error： %@", error);
    
  } else {
    // 不带耳机，音乐需要输出到手机的扬声器，而不是听筒
    HBAKSettings.defaultToSpeaker = false;
    HBAKSettings.disableAVAudioSessionCategoryManagement = true;
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    [[HBAudioSession sharedSession] setActive:YES];
    NSLog(@"session error： %@", error);
  }
  
  self.bus = 0;
  self.recordBufferDuration = 16384/HBAKSettings.sampleRate;
  
  NSError *error = nil;
  NSURL *saveURL = [NSURL fileURLWithPath:self.savePath];
  // Audio files cannot be non-interleaved. Ignoring setting AVLinearPCMIsNonInterleaved YES. 在此方法调用处有解释
  self.saveAudioFile = [[AVAudioFile alloc] initForWriting:saveURL settings:[HBAKSettings audioFormat].settings error:&error];
  
  //MARK: - 1. 麦克风
  if (!_mic) {
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
    
    _mic = [[HBAKMicrophone alloc] initWithFormat:audioFormat];
    
    // 配置麦克风的Node
    NSMutableArray *mixArray1 = [NSMutableArray array];
    [mixArray1 addObject:_mic];
    self.micMixer = [[HBAKMixer alloc] initWithInputs:mixArray1];
    
    // gain 控制麦克风的音量是否输入到扬声器
    self.micBooster = [[HBAKBooster alloc] initWithNode:self.micMixer gain:0];
  }
  
  if (!HBAudioKit.output || HBAudioKit.output != self.micBooster) {
    @try {
      [HBAudioKit disconnectAllInputs];
      HBAudioKit.output = self.micBooster;
    } @catch (NSException *exception) {
      
    } @finally {
      
    }
  }
}

- (void)startRecordWithProcessingCallback:(RecorderProcessingCallback)processingCallback {
  
  [self setupMainMixer];
  self.totalRecordBufferFrameLength = 0;
  self.processingCallback = processingCallback;
  
  if (!HBAudioKit.engine.isRunning) {
    @try {
      NSError *error = nil;
      [HBAudioKit startAndReturnError:&error];
      if (error) {
        NSLog(@"Record:: start -- %@", error);
      }
    } @catch (NSException *exception) {
      
    } @finally {
      
    }
  }
  
  self.innerSaveMixNode = self.micMixer.avAudioNode;
  [self innerMixerSatrtRecord];
}

/// 停止所有录制操作
- (void)stopRecorderOperationCompletion:(nullable void(^)(void))completion {
  [self innerMixerStopRecordCompletion:^{
    if (HBAudioKit.engine.isRunning) {
      NSError *error = nil;
      [HBAudioKit stopAndReturnError:&error];
      
      if (error) {
        NSLog(@"Record stop Error: %@", error);
      }
    }
    
    if (completion) {
      completion();
    }
  }];
}

#pragma mark - Private

- (void)addNewRecordBufferFrameLength:(uint32_t)bufferFrameLength rms:(float)rms {
  self.recordBufferDuration = (bufferFrameLength*1.0f)/HBAKSettings.sampleRate;
  self.totalRecordBufferFrameLength += bufferFrameLength;
  
  if (self.processingCallback) {
    self.processingCallback(rms, bufferFrameLength, self.totalRecordBufferFrameLength);
  }
}

- (void)innerMixerSatrtRecord {
  AVAudioFrameCount bufferLength = 1024;
  
    __weak __typeof(&*self)weakSelf = self;
  [self.innerSaveMixNode installTapOnBus:self.bus bufferSize:bufferLength format:nil block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
    @try {
      // 更新 buffer 时长和计算时间
      int vOffset = 1024;
      float *l = buffer.floatChannelData[0];
      NSInteger offset = buffer.frameCapacity - vOffset;
      float *r = &l[offset];
      float rms = [HBAudioKit RMS:r length:vOffset];
      
      [weakSelf addNewRecordBufferFrameLength:buffer.frameLength rms:rms];
      
      NSError *error = nil;
      [weakSelf.saveAudioFile writeFromBuffer:buffer error:&error];
      if (error) {
        NSLog(@"Record:: write buffer error -- %@", error);
      }
    } @catch (NSException *exception) {
      
    } @finally {
      
    }
  }];
}

// 全局的存储逻辑唯一，在一处存储
- (void)innerMixerStopRecordCompletion:(void(^)(void))completion {
  if (!self.innerSaveMixNode) {
    if (completion) {
      completion();
    }
    return;
  }
  double delayTime = self.recordBufferDuration;
  NSLog(@"Record:: delay save -- %lf", delayTime);
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.innerSaveMixNode removeTapOnBus:self.bus];
    self.innerSaveMixNode = nil;
    if (completion) {
      completion();
    }
  });
}

#pragma mark - Notification

- (void)didEnterBackground {
  
}

- (void)willEnterForeground {
  
}

- (void)didReceiveMemoryWarning {
  
}

- (void)routeChange:(NSNotification*)notification {
  NSDictionary *interuptionDict = notification.userInfo;
  
  NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
  switch (routeChangeReason) {
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
    {
      NSLog(@"Recorder::  ----------- 耳机插入");
      dispatch_async(dispatch_get_main_queue(), ^{
        //做操作,用主线程调用,如果不用主线程会报黄,提示,从一个线程跳到另一个线程容易产生崩溃,所以这里要用主线程去做操作
        
      });
    }
      break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
      //耳机拔出
    {
      NSLog(@"Recorder::  ----------- 耳机拔出");
      dispatch_async(dispatch_get_main_queue(), ^{
        //做操作,用主线程调用,如果不用主线程会报黄,提示,从一个线程跳到另一个线程容易产生崩溃,所以这里要用主线程去做操作
        
      });
    }
      break;
    case AVAudioSessionRouteChangeReasonOverride:
    {
      if (HBAKSettings.headPhonesPlugged) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        });
      } else {
        AVAudioSessionRouteDescription*route = [[AVAudioSession sharedInstance] currentRoute];
        for (AVAudioSessionPortDescription * desc in [route outputs]) {
            NSLog(@"当前声道%@",[desc portType]);
            NSLog(@"输出源名称%@",[desc portName]);
          dispatch_async(dispatch_get_main_queue(), ^{
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
          });
        }
      }
    }
    break;
  }
}

- (void)exchangePCMToMP3Completion:(void(^)(BOOL success, NSString *outputPath))completion {
    NSString *replaceString = [NSString stringWithFormat:@"%.0f.mp3", [[NSDate date] timeIntervalSince1970]];
    NSString *outputPath = [self.savePath stringByReplacingOccurrencesOfString:@"audio.pcm" withString:replaceString];
    [self.class exchangePCMToMP3WithFilePath:self.savePath resultPath:outputPath completion:^(BOOL success) {
        if (completion) {
            completion(success, outputPath);
        }
    }];
}

#pragma mark - M4AtoMP3

+ (void)exchangePCMToMP3WithFilePath:(NSString *)filePath resultPath:(NSString *)resultPath completion:(void(^)(BOOL success))completion {
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    if (completion) {
      completion(NO);
    }
    return;
  }
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:resultPath error:&error];
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    BOOL success = YES;
    @try {
      FILE *pcm = fopen([filePath cStringUsingEncoding:1], "rb");//被转换的音频文件位置
      fseek(pcm, 4*1024, SEEK_CUR);
      FILE *mp3 = fopen([resultPath cStringUsingEncoding:1], "wb");//生成的Mp3文件位置
      
      /*
       lame设置参考 https://www.jianshu.com/p/5208d6dcd7eb
      */
      
      // 初始化lame编码器
      lame_t lame = lame_init();
      // 设置lame mp3编码的采样率 / 声道数 / 比特率
      double sampleRate = [HBAudioSession sharedSession].audioFormat.sampleRate;
      int channelCount = [HBAudioSession sharedSession].audioFormat.channelCount;
      lame_set_in_samplerate(lame, sampleRate);
      lame_set_num_channels(lame, channelCount);
      lame_set_out_samplerate(lame, 16000);
      lame_set_quality(lame, 7); // MP3音频质量.0~9.其中0是最好,非常慢,9是最差.
      lame_set_brate(lame, 32); // 设置为32和安卓保持统一 32是32000 bit_rate = 32kbps
      // lame_set_VBR(lame, vbr_default); // 设置mp3的编码方式,不采用VBR的模式，会在服务端显示MP3的时长显示不正确
    
      lame_init_params(lame);
      
      int bufferSize = 1024*8*2;
      float buffer[bufferSize];
      float leftBuffer[bufferSize/2];
      float rightBuffer[bufferSize/2];
      unsigned char mp3_buffer[bufferSize];
      size_t readBufferSize = 0;
      
      /*
       Float32 32 bit IEEE float:  1 sign bit, 8 exponent bits, 23 fraction bits
       存储的是44100, 2chanel ,Float 32 4个字节
       
       需要特别注意的是下面我们从文件流每次读取两个字节的数据，依次存入buffer，这里由于demo处理的是16位PCM数据，所以左右声道各占两个字节，
       如果是8bit或者32bit则需要分别读取1个字节和4个字节数据。这样才能分离出左右声道数据
       
       因为是Float32 一个声道占4个字节 所以下面读取的是4个长度
       参考: https://www.jianshu.com/p/f62cba614a12
      **/
      
      // 确认buffer的长度, 通过sizeof验证过是正确的，debug控制台上看到的是一半的数据，是不对的
      while ((readBufferSize = fread(buffer, 4, bufferSize, pcm)) > 0) {
        for(int i = 0; i < readBufferSize; i++){
            if(i % 2 == 0){
              leftBuffer[i/2] = buffer[i];
            } else{
              rightBuffer[i/2] = buffer[i];
            }
        }
        size_t wroteSize = lame_encode_buffer_ieee_float(lame, leftBuffer, rightBuffer, (int)(readBufferSize / 2), mp3_buffer, bufferSize);
        if (wroteSize < 0) {
          NSLog(@"lame encode error: %zd",wroteSize);
          success = NO;
          break;
        }
        fwrite(mp3_buffer, wroteSize, 1, mp3);
      }
      
      size_t wroteSize = lame_encode_flush(lame, mp3_buffer, bufferSize);
      if (wroteSize < 0) {
        NSLog(@"lame encode error: %zd",wroteSize);
        success = NO;
      }
      
      fwrite(mp3_buffer, wroteSize, 1, mp3);
      //写入Mp3 VBR Tag，不是必须的步骤
      lame_mp3_tags_fid(lame, mp3);
      
      lame_close(lame);
      fclose(mp3);
      fclose(pcm);
    }
    @catch (NSException *exception) {
      NSLog(@"lame exchange error %@",[exception description]);
      
      success = NO;
    }
    @finally {
      // 转码完成
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (completion) {
        completion(success);
      }
    });
  });
}

@end
