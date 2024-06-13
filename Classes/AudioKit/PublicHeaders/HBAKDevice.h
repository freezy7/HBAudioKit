//
//  HBAKDevice.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBAKDevice : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic) int nInputChannels;
@property (nonatomic) int nOutputChannels;

@property (nonatomic, copy) NSString *deviceID;

- (instancetype)initWithName:(NSString *)name deviceID:(NSString *)deviceID dataSource:(NSString *)dataSource;
- (instancetype)initWithPortescription:(AVAudioSessionPortDescription *)portDescription;

- (AVAudioSessionPortDescription *)portDescription;
- (AVAudioSessionDataSourceDescription *)dataSource;

@end

NS_ASSUME_NONNULL_END
