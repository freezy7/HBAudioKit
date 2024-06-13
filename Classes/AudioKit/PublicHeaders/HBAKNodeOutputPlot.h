//
//  HBAKNodeOutputPlot.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/9.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HBAudioKit.h"
#import "HBAKMicrophone.h"
#import "HBAKBooster.h"
#import "HBAKPlayer.h"
#import "HBAKMixer.h"

NS_ASSUME_NONNULL_BEGIN

// 波形图，暂时未完工，后续再处理 @dcc
@interface HBAKNodeOutputPlot : UIView

@property (nonatomic, strong, nullable) HBAKNode *node;
@property (nonatomic) BOOL isNotConnected;

@property (nonatomic, strong) UIColor *color;

- (instancetype)initWithInput:(nullable HBAKNode *)node frame:(CGRect)frame bufferSize:(int)bufferSize;

- (void)resume;
- (void)pause;
- (void)reconnect;

@end

NS_ASSUME_NONNULL_END
