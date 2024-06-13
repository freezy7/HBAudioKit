//
//  HBAKConnection.h
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HBAKInput;

/// A transitory used to pass connection information.
@interface HBAKInputConnection : NSObject

@property (nonatomic, strong) HBAKInput *node;
@property (nonatomic) int bus;

- (instancetype)initWithNode:(HBAKInput *)node bus:(int)bus;
- (AVAudioConnectionPoint *)avConnection;

@end

@protocol HBAKOutputProtocol <NSObject>

- (AVAudioNode *)outputNode;

@end

@protocol AKToggleableProtocol <NSObject>

/// Tells whether the node is processing (ie. started, playing, or active)
- (BOOL)isStarted;

/// Function to start, play, or activate the node, all do the same thing
- (void)start;

/// Function to stop or bypass the node, both are equivalent
- (void)stop;

/// Synonym for isStarted that may make more sense with musical instruments
- (BOOL)isPlaying;

/// Antonym for isStarted
- (BOOL)isStopped;

/// Antonym for isStarted that may make more sense with effects
- (BOOL)isBypassed;

/// Synonym to start that may more more sense with musical instruments
- (void)play;

/// Synonym for stop that may make more sense with effects
- (void)bypass;

@end

@interface HBAKOutput : NSObject <HBAKOutputProtocol, AKToggleableProtocol>

/// Output connection points of outputNode.
@property (nonatomic, strong) NSArray <AVAudioConnectionPoint *> *connectionPoints;

/// Disconnects all outputNode's output connections.
- (void)disconnectOutput;

/// Breaks connection from outputNode to an input's node if exists.
///   - Parameter from: The node that output will disconnect from.
- (void)disconnectOutputFrom:(HBAKInput *)input;

/// Add a connection to an input using the input's nextInput for the bus.
- (HBAKInput *)connectToNode:(HBAKInput *)node;

/// Add a connection to input.node on input.bus.
///   - Parameter input: Contains node and input bus used to make a connection.
- (HBAKInput *)connectToInput:(HBAKInputConnection *)input;

/// Add a connection to node on a specific bus.
- (HBAKInput *)connectToNode:(HBAKInput *)node bus:(int)bus;

/// Add an output connection to each input in inputs.
///   - Parameter nodes: Inputs that will be connected to.
- (NSArray <HBAKInput *> *)connectToNodes:(NSArray <HBAKInput *> *)nodes;

/// Add an output connection to each connectionPoint in toInputs.
///   - Parameter toInputs: Inputs that will be connected to.
- (NSArray <HBAKInput *> *)connectToInputs:(NSArray <HBAKInputConnection *> *)inputs;

/// Add an output connectionPoint.
///   - Parameter connectionPoint: Input that will be connected to.
- (void)connectToConnectionPoint:(AVAudioConnectionPoint *)connectionPoint;

/// Sets output connection, removes existing output connections.
///   - Parameter node: Input that output will be connected to.
- (HBAKInput *)setOutputToNode:(HBAKInput *)node;

/// Sets output connection, removes previously existing output connections.
///   - Parameter node: Input that output will be connected to.
///   - Parameter bus: The bus on the input that the output will connect to.
///   - Parameter format: The format of the connection.
- (HBAKInput *)setOutputToNode:(HBAKInput *)node bus:(int)bus format:(AVAudioFormat *)format;

/// Sets output connections to an array of inputs, removes previously existing output connections.
///   - Parameter nodes: Inputs that output will be connected to.
///   - Parameter format: The format of the connections.
- (NSArray <HBAKInput *> *)setOutputToNodes:(NSArray <HBAKInput *> *)nodes format:(AVAudioFormat *)format;

/// Sets output connections to an array of inputConnectios, removes previously existing output connections.
///   - Parameter toInputs: Inputs that output will be connected to.
- (NSArray <HBAKInput *> *)setOutputToInputs:(NSArray <HBAKInputConnection *> *)inputs;

/// Sets output connections to an array of inputConnectios, removes previously existing output connections.
///   - Parameter toInputs: Inputs that output will be connected to.
///   - Parameter format: The format of the connections.
- (NSArray <HBAKInput *> *)setOutputToInputs:(NSArray <HBAKInputConnection *> *)inputs format:(AVAudioFormat *)format;

/// Sets output connections to a single connectionPoint, removes previously existing output connections.
///   - Parameter connectionPoint: Input that output will be connected to.
- (void)setOutputToConnectionPoint:(AVAudioConnectionPoint *)connectionPoint;

/// Sets output connections to a single connectionPoint, removes previously existing output connections.
///   - Parameter connectionPoint: Input that output will be connected to.
///   - Parameter format: The format of the connections.
- (void)setOutputToConnectionPoint:(AVAudioConnectionPoint *)connectionPoint format:(AVAudioFormat *)format;

/// Sets output connections to an array of connectionPoints, removes previously existing output connections.
///   - Parameter connectionPoints: Inputs that output will be connected to.
///   - Parameter format: The format of the connections.
- (void)setOutputToConnectionPoints:(NSArray <AVAudioConnectionPoint *> *)connectionPoints format:(AVAudioFormat *)format;

@end

@interface HBAKInput : HBAKOutput

/// The node that an output's node can connect to.  Default implementation will return outputNode.
@property (nonatomic, strong) AVAudioNode *inputNode;

/// The input bus that should be used for an input connection.  Default implementation is 0.  Multi-input nodes
/// should return an open bus.
///
///   - Return: An inputConnection object conatining self and the input bus to use for an input connection.
@property (nonatomic, strong) HBAKInputConnection *nextInput;

/// Disconnects all inputs
- (void)disconnectInput;

/// Disconnects input on a bus.
- (void)disconnectInputInBus:(int)bus;

/// Creates an input connection object with a bus number.
///   - Return: An inputConnection object conatining self and the input bus to use for an input connection.
- (HBAKInputConnection *)inputInBus:(AVAudioNodeBus)bus;

@end

@interface HBAKConnection : NSObject

@end

NS_ASSUME_NONNULL_END
