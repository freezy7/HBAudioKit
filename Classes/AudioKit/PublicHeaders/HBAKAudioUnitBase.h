//
//  HBAKAudioUnitBase.h
//  ProtonCrew
//
//  Created by R_style_Man on 2021/12/5.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#ifdef __OBJC__
#define AK_ENUM(a) enum __attribute__((enum_extensibility(open))) a : int
#define AK_SWIFT_TYPE __attribute((swift_newtype(struct)))
#else
#define AK_ENUM(a) enum a
#define AK_SWIFT_TYPE
#endif

typedef void* HBAKDSPRef AK_SWIFT_TYPE;

#import "HBBufferedAudioUnit.h"
#import "HBAKDSPBase.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface AUParameter(Ext_HB)
//-(_Nonnull instancetype)init:(NSString * _Nonnull)identifier
//                        name:(NSString * _Nonnull)name
//                     address:(AUParameterAddress)address
//                         min:(AUValue)min
//                         max:(AUValue)max
//                        unit:(AudioUnitParameterUnit)unit
//                       flags:(AudioUnitParameterOptions)flags;

+(_Nonnull instancetype)parameterWithIdentifier:(NSString * _Nonnull)identifier
                                           name:(NSString * _Nonnull)name
                                        address:(AUParameterAddress)address
                                            min:(AUValue)min
                                            max:(AUValue)max
                                           unit:(AudioUnitParameterUnit)unit
                                          flags:(AudioUnitParameterOptions)flags;

+(_Nonnull instancetype)parameterWithIdentifier:(NSString * _Nonnull)identifier
                                           name:(NSString * _Nonnull)name
                                        address:(AUParameterAddress)address
                                            min:(AUValue)min
                                            max:(AUValue)max
                                           unit:(AudioUnitParameterUnit)unit;
//+(_Nonnull instancetype)frequency:(NSString * _Nonnull)identifier
//                             name:(NSString * _Nonnull)name
//                          address:(AUParameterAddress)address;

@end

@interface AUParameterTree(Ext_HB)
+(_Nonnull instancetype)hb_treeWithChildren:(NSArray<AUParameter *> * _Nonnull)children;
@end

@interface HBAKAudioUnitBase : HBBufferedAudioUnit

/** Pointer to HBAKDSPBase subclass. */
@property (readonly) HBAKDSPRef _Nonnull dsp;

/**
 This method should be overridden by the specific AU code, because it knows how to set up
 the DSP code. It should also be declared as public in the h file, but that causes problems
 because Swift wants to process as a bridging header, and it doesn't understand what a DSPBase
 is. I'm not sure the standard way to deal with this.
 */

- (HBAKDSPRef _Nonnull)initDSPWithSampleRate:(double)sampleRate channelCount:(AVAudioChannelCount)count;

/**
 Sets the parameter tree. The important piece here is that setting the parameter tree
 triggers the setup of the blocks for observer, provider, and string representation. See
 the .m file. There may be a better way to do what is needed here.
 */

- (void)setParameterTree:(AUParameterTree *_Nullable)tree;

- (AUValue)parameterWithAddress:(AUParameterAddress)address;
- (void)setParameterWithAddress:(AUParameterAddress)address value:(AUValue)value;
- (void)setParameterImmediatelyWithAddress:(AUParameterAddress)address value:(AUValue)value;

// Add for compatibility with AKAudioUnit

- (void)start;
- (void)stop;
- (void)clear;
- (void)initializeConstant:(AUValue)value;

// Common for oscillating effects
- (void)setupWaveform:(int)size;
- (void)setWaveformValue:(float)value atIndex:(UInt32)index;

// Convolution and Phase-Locked Vocoder
- (void)setupAudioFileTable:(float *_Nonnull)data size:(UInt32)size;
- (void)setPartitionLength:(int)partitionLength;
- (void)initConvolutionEngine;

@property (readonly) BOOL isPlaying;
@property (readonly) BOOL isSetUp;

@end

NS_ASSUME_NONNULL_END
