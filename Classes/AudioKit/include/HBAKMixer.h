//
//  HBAKMixer.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBAKMixer : HBAKNode

@property (nonatomic) double volume;

- (instancetype)initWithInputs:(NSArray <HBAKNode *> *)inputs;

@end

NS_ASSUME_NONNULL_END
