//
//  HBAKNode.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKNode.h"
#import "HBAudioKit.h"

@implementation HBAKNode

/// Create the node
- (instancetype)init {
    self = [super init];
    if (self) {
        self.avAudioNode = [AVAudioNode new];
    }
    return self;
}

- (instancetype)initWithAvAudioUnit:(AVAudioUnit *)avAudioUnit attach:(BOOL)attach {
    self = [super init];
    if (self) {
        self.avAudioUnit = avAudioUnit;
        self.avAudioNode = avAudioUnit;
        
        if (attach) {
            [HBAudioKit.engine attachNode:avAudioUnit];
        }
    }
    return self;
}

- (instancetype)initWithAvAudioNode:(AVAudioNode *)avAudioNode attach:(BOOL)attach {
    self = [super init];
    if (self) {
        self.avAudioNode = avAudioNode;
        
        if (attach) {
            [HBAudioKit.engine attachNode:avAudioNode];
        }
    }
    return self;
}

- (AVAudioNode *)avAudioUnitOrNode {
    return self.avAudioUnit?self.avAudioUnit:self.avAudioNode;
}

- (void)detach {
    AVAudioNode *node = self.avAudioUnitOrNode;
    if (node) {
        [HBAudioKit detachNodes:@[node]];
    }
}

#pragma mark - HBAKOutput

- (AVAudioNode *)outputNode {
    return self.avAudioUnitOrNode;
}


@end
