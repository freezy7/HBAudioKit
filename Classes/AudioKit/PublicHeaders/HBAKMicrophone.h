//
//  HBAKMicrophone.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKNode.h"
#import "HBAKDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBAKMicrophone : HBAKNode

/// Output Volume (Default 1)
@property (nonatomic) double volume;

- (void)setDevice:(HBAKDevice *)device;

- (instancetype)initWithFormat:(AVAudioFormat *)format;

- (void)setAVAseesionSampleRate:(double)sampleRate;

- (AVAudioFormat *)getFormatForDevice;

@end

NS_ASSUME_NONNULL_END
