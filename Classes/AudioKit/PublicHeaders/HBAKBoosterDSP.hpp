//
//  AKBoosterDSP.hpp
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#pragma once

#import <AVFoundation/AVFoundation.h>
#import "HBAKParameterRamp.hpp"
#import "HBAKExponentialParameterRamp.hpp" // to be deleted

typedef NS_ENUM (AUParameterAddress, HBAKBoosterParameter) {
  HBAKBoosterParameterLeftGain,
  HBAKBoosterParameterRightGain,
  HBAKBoosterParameterRampDuration,
  HBAKBoosterParameterRampType
};

#ifndef __cplusplus

HBAKDSPRef createBoosterDSP(int channelCount, double sampleRate);

#else

#import "HBAKDSPBase.hpp"

/**
 A simple DSP kernel. Most of the plumbing is in the base class. All the code at this
 level has to do is supply the core of the rendering code. A less trivial example would probably
 need to coordinate the updating of DSP parameters, which would probably involve thread locks,
 etc.
 */

struct HBAKBoosterDSP : HBAKDSPBase {
private:
    struct InternalData;
    std::unique_ptr<InternalData> data;

public:
    HBAKBoosterDSP();

    void setParameter(AUParameterAddress address, float value, bool immediate) override;
    float getParameter(AUParameterAddress address) override;
    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override;
};

#endif
