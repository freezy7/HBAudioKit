//
//  HBAKAudioUnitBase.m
//  ProtonCrew
//
//  Created by R_style_Man on 2021/12/5.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKAudioUnitBase.h"
#import "HBAKSettings.h"
#import <AVFoundation/AVFoundation.h>

@implementation AUParameter(Ext_HB)

//-(instancetype)init:(NSString *)identifier
//               name:(NSString *)name
//            address:(AUParameterAddress)address
//                min:(AUValue)min
//                max:(AUValue)max
//               unit:(AudioUnitParameterUnit)unit
//              flags:(AudioUnitParameterOptions)flags {
//
//    return self = [AUParameterTree createParameterWithIdentifier:identifier
//                                                            name:name
//                                                         address:address
//                                                             min:min
//                                                             max:max
//                                                            unit:unit
//                                                        unitName:nil
//                                                           flags:flags
//                                                    valueStrings:nil
//                                             dependentParameters:nil];
//}

+(instancetype)parameterWithIdentifier:(NSString *)identifier
                                  name:(NSString *)name
                               address:(AUParameterAddress)address
                                   min:(AUValue)min
                                   max:(AUValue)max
                                  unit:(AudioUnitParameterUnit)unit
                                 flags:(AudioUnitParameterOptions)flags {
    return [AUParameterTree createParameterWithIdentifier:identifier
                                                     name:name
                                                  address:address
                                                      min:min
                                                      max:max
                                                     unit:unit
                                                 unitName:nil
                                                    flags:flags
                                             valueStrings:nil
                                      dependentParameters:nil];
}

+(instancetype)parameterWithIdentifier:(NSString *)identifier
                                  name:(NSString *)name
                               address:(AUParameterAddress)address
                                   min:(AUValue)min
                                   max:(AUValue)max
                                  unit:(AudioUnitParameterUnit)unit {
    return [AUParameterTree createParameterWithIdentifier:identifier
                                                     name:name
                                                  address:address
                                                      min:min
                                                      max:max
                                                     unit:unit
                                                 unitName:nil
                                                    flags:0
                                             valueStrings:nil
                                      dependentParameters:nil];
}

//+(instancetype)frequency:(NSString *)identifier
//                    name:(NSString *)name
//                 address:(AUParameterAddress)address {
//    return [AUParameter parameterWithIdentifier:identifier
//                             name:name
//                          address:address
//                              min:20
//                              max:22050
//                             unit:kAudioUnitParameterUnit_Hertz];

@end

@implementation AUParameterTree(Ext_HB)

+(instancetype)hb_treeWithChildren:(NSArray<AUParameter *> *)children {
    AUParameterTree *tree = [AUParameterTree createTreeWithChildren:children];
    if (tree == nil) {
        return nil;
    }
    
    tree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        AUValue value = valuePtr == nil ? param.value : *valuePtr;
        return [NSString stringWithFormat:@"%.3f", value];
        
    };
    return tree;
    
}

@end

@implementation HBAKAudioUnitBase

// Convenience for casting (AKDSPRef)_dsp to AKDSPBase;
- (HBAKDSPBase *)kernel {
    return (HBAKDSPBase *)_dsp;
}

@synthesize parameterTree = _parameterTree;

- (AUValue)parameterWithAddress:(AUParameterAddress)address {
    return self.kernel->getParameter(address);
}

- (void)setParameterWithAddress:(AUParameterAddress)address value:(AUValue)value {
    self.kernel->setParameter(address, value);
}

- (void)setParameterImmediatelyWithAddress:(AUParameterAddress)address value:(AUValue)value {
    self.kernel->setParameter(address, value, true);
}

- (void)start {
    self.kernel->start();
}

- (void)stop {
    self.kernel->stop();
}

- (void)clear {
    self.kernel->clear();
}

- (void)initializeConstant:(AUValue)value {
    self.kernel->initializeConstant(value);
}

- (BOOL)isPlaying {
    return self.kernel->isPlaying();
}

- (BOOL)isSetUp {
    return self.kernel->isSetup();
}

- (void)setupWaveform:(int)size {
    self.kernel->setupWaveform((uint32_t)size);
}

- (void)setWaveformValue:(float)value atIndex:(UInt32)index {
    self.kernel->setWaveformValue(index, value);
}
- (void)setupAudioFileTable:(float *)data size:(UInt32)size {
    self.kernel->setUpTable(data, size);
}

- (void)setPartitionLength:(int)partitionLength {
    self.kernel->setPartitionLength(partitionLength);
}

- (void)initConvolutionEngine {
    self.kernel->initConvolutionEngine();
}

/**
 This should be overridden. All the base class does is make sure that the pointer to the
 DSP is invalid.
 */
- (HBAKDSPRef)initDSPWithSampleRate:(double)sampleRate channelCount:(AVAudioChannelCount)count {
    return (_dsp = NULL);
}

/**
 Sets up the parameter tree. The reason this method must exist explicitly is that the blocks
 associated with the parameter tree must be set up here. This is because the pointer to the
 parameterTree is being changed. If we set up the blocks in the init function, they would be
 associated with the "old" parameterTree when the parameterTree is setup for real.
 
 Otherwise, this code is just the same as what is in the Apple example code init function.
 */

- (void)setParameterTree:(AUParameterTree *)tree {
    _parameterTree = tree;
    
    // Make a local pointer to the kernel to avoid capturing self.
    __block HBAKDSPBase *kernel = self.kernel;
    
    // implementorValueObserver is called when a parameter changes value.
    _parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        kernel->setParameter(param.address, value);
    };
    
    // implementorValueProvider is called when the value needs to be refreshed.
    _parameterTree.implementorValueProvider = ^(AUParameter *param) {
        return kernel->getParameter(param.address);
    };
    
    // implementorStringFromValueCallback is called to provide string representations of parameter values.
    _parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        // If value is nil, use the current value of the parameter.
        AUValue value = valuePtr == nil ? param.value : *valuePtr;
        return [NSString stringWithFormat:@"%.2f", value];
    };
}

/**
 Much simpler than the Apple example code version. We don't deal with presets, we don't set up
 a specific parameterTree, etc. The block set for parameterTree is moved to setParameterTree
 */

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription
                                     options:(AudioComponentInstantiationOptions)options
                                       error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    if (self == nil) {
        return nil;
    }
    
    // Initialize a default format for the busses.
    AVAudioFormat *arbitraryFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:HBAKSettings.sampleRate
                                                                                    channels:HBAKSettings.channelCount];
    
    _dsp = [self initDSPWithSampleRate:arbitraryFormat.sampleRate
                          channelCount:arbitraryFormat.channelCount];
    
    // Create a default empty parameter tree.
    _parameterTree = [AUParameterTree hb_treeWithChildren:@[]];
    
    return self;
}

// Allocate resources required to render.
// Hosts must call this to initialize the AU before beginning to render.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }
    
    AVAudioFormat *format = self.outputBusses[0].format;
    self.kernel->init(format.channelCount, format.sampleRate);
    self.kernel->reset();
    
    return YES;
}

- (ProcessEventsBlock)processEventsBlock:(AVAudioFormat *)format {
    __block HBAKDSPBase *kernel = self.kernel;
    return ^(AudioBufferList *inBuffer,
             AudioBufferList *outBuffer,
             const AudioTimeStamp *timestamp,
             AVAudioFrameCount frameCount,
             const AURenderEvent *eventListHead) {
        kernel->setBuffers(inBuffer, outBuffer);
        kernel->processWithEvents(timestamp, frameCount, eventListHead);
    };
}

// Deallocate resources allocated by allocateRenderResourcesAndReturnError:
// Hosts should call this after finishing rendering.

- (void)deallocateRenderResources {
    self.kernel->deinit();
    [super deallocateRenderResources];
}

// Expresses whether an audio unit can process in place.
// In-place processing is the ability for an audio unit to transform an input signal to an
// output signal in-place in the input buffer, without requiring a separate output buffer.
// A host can express its desire to process in place by using null mData pointers in the output
// buffer list. The audio unit may process in-place in the input buffers.
// See the discussion of renderBlock.
// Partially bridged to the v2 property kAudioUnitProperty_InPlaceProcessing, the v3 property is not settable.
// Should be overriden in subclasses
- (BOOL)canProcessInPlace {
    return NO;   // OK THIS IS DIFFERENT FROM APPLE EXAMPLE CODE
}

// ----- END UNMODIFIED COPY FROM APPLE CODE -----

- (void)dealloc {
    delete self.kernel;
}


@end
