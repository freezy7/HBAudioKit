//
//  HBAKNodeOutputPlot.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/9.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKNodeOutputPlot.h"

@interface HBAKNodeOutputPlot () {
    BOOL _isConnected;
}

@end

@implementation HBAKNodeOutputPlot

- (void)dealloc {
    [_node.avAudioUnitOrNode removeTapOnBus:0];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupNode:HBAudioKit.output];
        [self setupReconnection];
    }
    return self;
}

- (instancetype)initWithInput:(nullable HBAKNode *)node frame:(CGRect)frame bufferSize:(int)bufferSize {
    self = [super initWithFrame:frame];
    if (self) {
        
        if (!node) {
            node = [HBAudioKit output];
        }
        [self setupNode:node];
        self.node = node;
        [self setupReconnection];
    }
    return self;
}

- (BOOL)isNotConnected {
    return !_isConnected;
}

- (void)setNode:(HBAKNode *)node {
    [self pause];
    [self resume];
}

- (void)setupNode:(HBAKNode *)input {
    if ([self isNotConnected]) {
        __weak __typeof(&*self)weakSelf = self;
        [input.avAudioUnitOrNode installTapOnBus:0 bufferSize:1024 format:nil block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            if (weakSelf) {
                
            }
        }];
    }
}

- (void)setupReconnection {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reconnect) name:@"IAAConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reconnect) name:@"IAADisconnected" object:nil];
}

- (void)resume {
    [self setupNode:self.node];
}

- (void)pause {
    if (_isConnected) {
        [_node.avAudioUnitOrNode removeTapOnBus:0];
        _isConnected = NO;
    }
}

- (void)reconnect {
    [self pause];
    [self resume];
}

@end
