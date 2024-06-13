//
//  AKBoosterDSP.mm
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#include "HBAKBoosterDSP.hpp"
#import "HBAKAudioUnitBase.h"

extern "C" HBAKDSPRef createBoosterDSP(int channelCount, double sampleRate)
{
    HBAKBoosterDSP *dsp = new HBAKBoosterDSP();
    dsp->init(channelCount, sampleRate);
    return dsp;
}

struct HBAKBoosterDSP::InternalData {
    HBAKParameterRamp leftGainRamp;
    HBAKParameterRamp rightGainRamp;
};

HBAKBoosterDSP::HBAKBoosterDSP() : data(new InternalData)
{
    data->leftGainRamp.setTarget(1.0, true);
    data->leftGainRamp.setDurationInSamples(10000);
    data->rightGainRamp.setTarget(1.0, true);
    data->rightGainRamp.setDurationInSamples(10000);
}

// Uses the ParameterAddress as a key
void HBAKBoosterDSP::setParameter(AUParameterAddress address, AUValue value, bool immediate)
{
    switch (address) {
        case HBAKBoosterParameterLeftGain:
            data->leftGainRamp.setTarget(value, immediate);
            break;
        case HBAKBoosterParameterRightGain:
            data->rightGainRamp.setTarget(value, immediate);
            break;
        case HBAKBoosterParameterRampDuration:
            data->leftGainRamp.setRampDuration(value, sampleRate);
            data->rightGainRamp.setRampDuration(value, sampleRate);
            break;
        case HBAKBoosterParameterRampType:
            data->leftGainRamp.setRampType(value);
            data->rightGainRamp.setRampType(value);
            break;
    }
}

// Uses the ParameterAddress as a key
float HBAKBoosterDSP::getParameter(AUParameterAddress address)
{
    switch (address) {
        case HBAKBoosterParameterLeftGain:
            return data->leftGainRamp.getTarget();
        case HBAKBoosterParameterRightGain:
            return data->rightGainRamp.getTarget();
        case HBAKBoosterParameterRampDuration:
            return data->leftGainRamp.getRampDuration(sampleRate);
    }
    return 0;
}

void HBAKBoosterDSP::process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset)
{
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
        int frameOffset = int(frameIndex + bufferOffset);
        // do ramping every 8 samples
        if ((frameOffset & 0x7) == 0) {
            data->leftGainRamp.advanceTo(now + frameOffset);
            data->rightGainRamp.advanceTo(now + frameOffset);
        }
        // do actual signal processing
        // After all this scaffolding, the only thing we are doing is scaling the input
        for (int channel = 0; channel < channelCount; ++channel) {
            float *in = (float *)inBufferListPtr->mBuffers[channel].mData  + frameOffset;
            float *out = (float *)outBufferListPtr->mBuffers[channel].mData + frameOffset;
            if (channel == 0) {
                *out = *in * data->leftGainRamp.getValue();
            } else {
                *out = *in * data->rightGainRamp.getValue();
            }
        }
    }
}
