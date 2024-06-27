//
//  ViewController.m
//  HBAudioKit
//
//  Created by HolidayBomb on 2024/6/12.
//

#import "ViewController.h"
#import "HBAudioKitFastRecorder.h"
#import "HBAudioKit-Swift.h"

@interface ViewController () {
    HBAudioKitFastRecorder *_fastRecord;
    
    BOOL _isRecording;
    
    NSString *_outputPath;
    
    AVAudioPlayer* digitalPlayer;
    
    TWFastRecorder *_twFastRecorder;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _fastRecord = [[HBAudioKitFastRecorder alloc] init];
    
    _twFastRecorder = [TWFastRecorder new];
}

- (IBAction)record:(id)sender {
    if (_isRecording) {
        _isRecording = false;
        [_twFastRecorder stopRecording];
    } else {
        _isRecording = true;
        AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {// 未询问用户是否授权
          AVAudioSession *audioSession = [AVAudioSession sharedInstance];
          if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            
            }];
          }
          return;
        } else if (videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied) {
          return;
        }
        
        [_twFastRecorder startRecordingWithProgressBlock:^(double duration) {
            NSLog(@"time: %.3f", duration);
        } speechBlock:^(NSString * _Nonnull speechText) {
            NSLog(@"%@", speechText);
        }];
    }
}

- (IBAction)play:(id)sender {
    NSString *replaceString = [NSString stringWithFormat:@"%.0f.mp3", [[NSDate date] timeIntervalSince1970]];
    NSString *outputPath = [_fastRecord.savePath stringByReplacingOccurrencesOfString:@"audio.pcm" withString:replaceString];
    
    [HBAudioKitFastRecorder exchangePCMToMP3WithFilePath:_fastRecord.savePath resultPath:outputPath completion:^(BOOL success) {
        if (success) {
            _outputPath = outputPath;
            
            NSLog(@"_outputPath: %@", _outputPath);
            
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
            [[AVAudioSession sharedInstance] setActive:true error:nil];
            
            NSURL *soundURL = [NSURL fileURLWithPath:_outputPath];
            
            NSError *error;
            digitalPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
            if (error) {
                NSLog(@"初始化音频播放器时发生错误: %@", [error localizedDescription]);
            } else {
                [digitalPlayer prepareToPlay];
            }
            digitalPlayer.numberOfLoops = 0; // 设置为负数表示无限循环
            
            [digitalPlayer play];
            
        }
    }];
}

@end
