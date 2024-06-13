//
//  HBAudioSession.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2020/3/29.
//  Copyright © 2020 ProtonCrew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 该类是对AVAudioSession的封装
 *
 */
@interface HBAudioSession : NSObject

+ (instancetype)sharedSession;

@property (nonatomic, strong) AVAudioFormat *inputMicAudioFormat;
@property (nonatomic, strong) AVAudioFormat *audioFormat;

- (void)setActive:(BOOL)active;

@end

@interface NSMutableArray<ObjectType> (HBAdditions)

/// 安全保护 anObject 为空的时候
- (void)hb_safeAddObject:(nullable ObjectType)anObject;

@end

@interface NSArray<ObjectType> (HBAdditions)

/**
 遍历数组，选取符合条件的元素集合
 和 swift 高阶函数 filter 类似
 
 @param block 返回 YES 表示保留，NO 则剔除
 @return 新数组（符合block的筛选条件）
 */
- (NSArray<ObjectType> *)hb_filterElements:(BOOL (^)(ObjectType elemtent))block;

/**
 提供数组元素类型转换的方法 比如 @[@(1),@(2),@(3)] => @[@"1",@"2",@"3"]
 转换失败用NSNull替换
 
 @param block 子元素转换成所对应的id类型, （注意：必有返回值）
 @return 新数组 新元素类型
 */
- (NSArray *)hb_map:(__nullable id (^)(ObjectType obj))block;

@end

NS_ASSUME_NONNULL_END
