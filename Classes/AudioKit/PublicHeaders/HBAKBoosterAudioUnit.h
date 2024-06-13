//
//  HBAKBoosterAudioUnit.h
//  ProtonCrew
//
//  Created by R_style_Man on 2021/12/5.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKAudioUnitBase.h"
#import "HBAKBoosterDSP.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface HBAKBoosterAudioUnit : HBAKAudioUnitBase

- (void)setParameter:(HBAKBoosterParameter)address value:(double)value;
- (void)setParameterImmediately:(HBAKBoosterParameter)address value:(double)value;

@property (nonatomic) double leftGain;
@property (nonatomic) double rightGain;

@property (nonatomic) double rampDuration;
@property (nonatomic) double rampType;


@end

NS_ASSUME_NONNULL_END
