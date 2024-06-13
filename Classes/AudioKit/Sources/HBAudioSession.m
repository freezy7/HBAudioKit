//
//  HBAudioSession.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2020/3/29.
//  Copyright © 2020 ProtonCrew. All rights reserved.
//

#import "HBAudioSession.h"

@interface HBAudioSession () {
    BOOL _isActive;
}


@end

@implementation HBAudioSession

+ (instancetype)sharedSession {
    static HBAudioSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [HBAudioSession new];
    });
    return session;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setActive:(BOOL)active {
    // 取消之前的延时操作
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    NSError *outError = nil;
    if (active) {
        BOOL isSuccess = [[AVAudioSession sharedInstance] setActive:active error:&outError];
        if (isSuccess) {
            _isActive = YES;
        }
        
        NSLog(@"session error： %@", outError);
    } else {
        [self performSelector:@selector(delay_setInActive) withObject:nil afterDelay:1];
    }
}

- (void)delay_setInActive {
    NSError *error = nil;
    BOOL isSuccess = [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (!isSuccess) {
        NSLog(@"激活其他音频错误 %@",error);
    } else {
        _isActive = NO;
        NSLog(@"激活其他音频成功了");
    }
}

@end

@implementation NSMutableArray (HBAdditions)

- (void)hb_safeAddObject:(id)anObject {
    if (anObject) {
        [self addObject:anObject];
    }
}

@end

@implementation NSArray(HBAdditions)

- (NSArray *)hb_filterElements:(BOOL (^)(id _Nonnull))block {
    NSAssert(block!=nil, @"block 不能为空, 但还是做了保护");
    
    NSIndexSet *indexSet = [self indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return !block ? NO : block(obj);
    }];
    
    return [self objectsAtIndexes:indexSet];
}

- (NSArray *)hb_map:(id  _Nonnull (^)(id _Nonnull))block {
    NSAssert(block!=nil, @"block 不能为空, 但还是做了保护");
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = !block ? [NSNull null] : block(obj);
        [result hb_safeAddObject:value];
    }];
    
    return result;
}

@end
