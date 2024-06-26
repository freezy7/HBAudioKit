//
//  AKExponentialParameterRamp.cpp
//  AudioKit
//
//  Created by Ryan Francesconi, revision history on Githbub.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#pragma once

#import "HBAKParameterRampBase.hpp" // have to put this here to get it included in umbrella header

#ifdef __cplusplus

// Currently Unused
struct HBAKExponentialParameterRamp : HBAKParameterRampBase {

    float computeValueAt(int64_t atSample) override {
        // position
        float minp = _startSample;
        float maxp = _startSample + _duration;

        // values
        float minv = log(_startValue);
        float maxv = log(_target);

        // calculate adjustment factor
        float scale = (maxv-minv) / (maxp-minp);
        
        _value = exp(minv + scale * (atSample-minp));

//        printf( "%6.4lf %6.4lf \n", _startValue, _target);
//        printf( "AKExponentialParameterRamp %lld %6.4lld %lld %6.4lf \n", _startSample, _duration, atSample, _value );
        return _value;
    }

};

#endif


