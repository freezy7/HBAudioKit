//
//  ViewController.m
//  HBAudioKit
//
//  Created by HolidayBomb on 2024/6/12.
//

#import "ViewController.h"
#import "HBAudioKitFastRecorder.h"

@interface ViewController () {
    HBAudioKitFastRecorder *_fastRecord;
    
    BOOL _isRecording;
    
    NSString *_outputPath;
    
    AVAudioPlayer* digitalPlayer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _fastRecord = [[HBAudioKitFastRecorder alloc] init];
}

- (IBAction)record:(id)sender {
    if (_isRecording) {
        _isRecording = false;
        [_fastRecord stopRecorderOperationCompletion:^{
            [self->_fastRecord exchangePCMToMP3Completion:^(BOOL success, NSString * _Nonnull outputPath) {
                self->_outputPath = outputPath;
            }];
        }];
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
        
        [_fastRecord startRecordWithProcessingCallback:^(float lVol, unsigned long currentLength, unsigned long totalLength) {
            
        }];
    }
}

- (IBAction)play:(id)sender {
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

@end
