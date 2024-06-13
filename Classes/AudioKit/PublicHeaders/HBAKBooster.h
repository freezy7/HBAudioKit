//
//  HBAKBooster.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKNode.h"
#import "HBAKBoosterAudioUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBAKBooster : HBAKNode

@property (nonatomic) double rampDuration;
@property (nonatomic) double rampType;

@property (nonatomic) double gain;

@property (nonatomic) double leftGain;
@property (nonatomic) double rightGain;

@property (nonatomic) double dB;

- (instancetype)initWithNode:(HBAKNode *)input gain:(double)gain;

@end

NS_ASSUME_NONNULL_END
