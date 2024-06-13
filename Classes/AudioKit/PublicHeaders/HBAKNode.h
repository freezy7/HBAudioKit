//
//  HBAKNode.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "HBAKConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBAKNode : HBAKInput

/// The internal AVAudioEngine AVAudioNode
@property (nonatomic, strong) AVAudioNode *avAudioNode;

/// The internal AVAudioUnit, which is a subclass of AVAudioNode with more capabilities
@property (nonatomic, strong) AVAudioUnit *avAudioUnit;

/// Returns either the avAudioUnit (preferred
- (AVAudioNode *)avAudioUnitOrNode;

/// Initialize the node from an AVAudioUnit
- (instancetype)initWithAvAudioUnit:(AVAudioUnit *)avAudioUnit attach:(BOOL)attach;

/// Initialize the node from an AVAudioNode
- (instancetype)initWithAvAudioNode:(AVAudioNode *)avAudioNode attach:(BOOL)attach;

// Subclasses should override to detach all internal nodes
- (void)detach;

@end

NS_ASSUME_NONNULL_END
