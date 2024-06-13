//
//  HBAKConnection.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKConnection.h"
#import "HBAudioKit.h"
#import "HBAudioSession.h"

@implementation HBAKInputConnection

- (instancetype)initWithNode:(HBAKInput *)node bus:(int)bus {
    self = [super init];
    if (self) {
        self.node = node;
        self.bus = bus;
    }
    return self;
}

- (AVAudioConnectionPoint *)avConnection {
    return [[AVAudioConnectionPoint alloc] initWithNode:self.node.inputNode bus:self.bus];
}

@end

@interface HBAKOutput () {
    NSArray<AVAudioConnectionPoint *> *_innerConnectionPoints;
}

@end

@implementation HBAKOutput

- (AVAudioNode *)outputNode {
    return nil;
}

- (void)setConnectionPoints:(NSArray<AVAudioConnectionPoint *> *)connectionPoints {
    _innerConnectionPoints = connectionPoints.copy;
    
    [HBAudioKit connectSourceNode:self.outputNode toDestNodes:connectionPoints fromSourceBus:0 format:HBAudioKit.format];
}

- (NSArray<AVAudioConnectionPoint *> *)connectionPoints {
    NSArray<AVAudioConnectionPoint *> *points = [self.outputNode.engine outputConnectionPointsForNode:self.outputNode outputBus:0];
    return points?points:@[];
}

- (void)disconnectOutput {
    [HBAudioKit.engine disconnectNodeOutput:self.outputNode];
}

- (void)disconnectOutputFrom:(HBAKInput *)input {
    self.connectionPoints = [self.connectionPoints hb_filterElements:^BOOL(AVAudioConnectionPoint * _Nonnull elemtent) {
        return elemtent.node != input.inputNode;
    }].mutableCopy;
}

#pragma mark - connect

- (HBAKInput *)connectToNode:(HBAKInput *)node {
    return [self connectToNode:node bus:node.nextInput.bus];
}

- (HBAKInput *)connectToInput:(HBAKInputConnection *)input {
    return [self connectToNode:input.node bus:input.bus];
}

- (HBAKInput *)connectToNode:(HBAKInput *)node bus:(int)bus {
    AVAudioConnectionPoint *connectPoint = [[AVAudioConnectionPoint alloc] initWithNode:node.inputNode bus:bus];
    NSMutableArray<AVAudioConnectionPoint *> *tempArray = [self.connectionPoints mutableCopy];
    [tempArray hb_safeAddObject:connectPoint];
    self.connectionPoints = tempArray.copy;
    return node;
}

- (NSArray<HBAKInput *> *)connectToNodes:(NSArray<HBAKInput *> *)nodes {
    NSArray <AVAudioConnectionPoint *> *connectPoints = [nodes hb_map:^AVAudioConnectionPoint * _Nullable(HBAKInput * _Nonnull obj) {
        return [obj.nextInput avConnection];
    }];
    
    if (connectPoints.count > 0) {
        NSMutableArray<AVAudioConnectionPoint *> *tempArray = [self.connectionPoints mutableCopy];
        [tempArray addObjectsFromArray:connectPoints];
        self.connectionPoints = tempArray.copy;
    }
    return nodes;
}

- (NSArray<HBAKInput *> *)connectToInputs:(NSArray<HBAKInputConnection *> *)inputs {
    NSArray <AVAudioConnectionPoint *> *connectPoints = [inputs hb_map:^AVAudioConnectionPoint * _Nullable(HBAKInputConnection * _Nonnull obj) {
        return [obj avConnection];
    }];
    
    if (connectPoints.count > 0) {
        NSMutableArray<AVAudioConnectionPoint *> *tempArray = [self.connectionPoints mutableCopy];
        [tempArray addObjectsFromArray:connectPoints];
        self.connectionPoints = tempArray.copy;
    }
    
    return [inputs hb_map:^HBAKInput * _Nullable(HBAKInputConnection * _Nonnull obj) {
        return obj.node;
    }];
}

- (void)connectToConnectionPoint:(AVAudioConnectionPoint *)connectionPoint {
    NSMutableArray<AVAudioConnectionPoint *> *tempArray = [self.connectionPoints mutableCopy];
    [tempArray hb_safeAddObject:connectionPoint];
    self.connectionPoints = tempArray.copy;
}

#pragma mark - set output

- (HBAKInput *)setOutputToNode:(HBAKInput *)node {
    return [self setOutputToNode:node bus:node.nextInput.bus format:HBAudioKit.format];
}

- (HBAKInput *)setOutputToNode:(HBAKInput *)node bus:(int)bus format:(AVAudioFormat *)format {
    [HBAudioKit connectNode1:self.outputNode toNode2:node.inputNode fromBus1:0 toBus2:bus format:format];
    return node;
}

- (NSArray<HBAKInput *> *)setOutputToNodes:(NSArray<HBAKInput *> *)nodes format:(AVAudioFormat *)format {
    NSArray <AVAudioConnectionPoint *> *connectPoints = [nodes hb_map:^AVAudioConnectionPoint * _Nullable(HBAKInput * _Nonnull obj) {
        return [obj.nextInput avConnection];
    }];
    
    [self setOutputToConnectionPoints:connectPoints format:format];
    
    return nodes;
}

- (NSArray<HBAKInput *> *)setOutputToInputs:(NSArray<HBAKInputConnection *> *)inputs {
    return [self setOutputToInputs:inputs format:HBAudioKit.format];
}

- (NSArray<HBAKInput *> *)setOutputToInputs:(NSArray<HBAKInputConnection *> *)inputs format:(AVAudioFormat *)format {
    
    NSArray <AVAudioConnectionPoint *> *connectPoints = [inputs hb_map:^AVAudioConnectionPoint * _Nullable(HBAKInputConnection * _Nonnull obj) {
        return [obj avConnection];
    }];
    
    [self setOutputToConnectionPoints:connectPoints format:format];
    
    return [inputs hb_map:^HBAKInput * _Nullable(HBAKInputConnection * _Nonnull obj) {
        return obj.node;
    }];
}

- (void)setOutputToConnectionPoint:(AVAudioConnectionPoint *)connectionPoint {
    [self setOutputToConnectionPoint:connectionPoint format:HBAudioKit.format];
}

- (void)setOutputToConnectionPoint:(AVAudioConnectionPoint *)connectionPoint format:(AVAudioFormat *)format {
    if (connectionPoint) {
        [self setOutputToConnectionPoints:@[connectionPoint] format:format];
    }
}

- (void)setOutputToConnectionPoints:(NSArray <AVAudioConnectionPoint *> *)connectionPoints format:(AVAudioFormat *)format {
    [HBAudioKit connectSourceNode:self.outputNode toDestNodes:connectionPoints fromSourceBus:0 format:format];
}

#pragma mark - AKToggleableProtocol

- (BOOL)isStarted {
    return false;
}

- (void)start {
    
}

- (void)stop {
    
}

- (BOOL)isPlaying {
    return [self isStarted];
}

- (BOOL)isStopped {
    return ![self isStarted];
}

- (BOOL)isBypassed {
    return ![self isStarted];
}

- (void)play {
    [self start];
}

- (void)bypass {
    [self stop];
}

@end

@implementation HBAKInput

- (AVAudioNode *)inputNode {
    return self.outputNode;
}

- (void)disconnectInput {
    [HBAudioKit.engine disconnectNodeInput:self.inputNode];
}

- (void)disconnectInputInBus:(int)bus {
    [HBAudioKit.engine disconnectNodeInput:self.inputNode bus:0];
}

- (HBAKInputConnection *)nextInput {
    if ([[self inputNode] isKindOfClass:AVAudioMixerNode.class]) {
        return [self inputInBus:[(AVAudioMixerNode *)[self inputNode] nextAvailableInputBus]];;
    }
    
    return [self inputInBus:0];
}

- (HBAKInputConnection *)inputInBus:(AVAudioNodeBus)bus {
    return [[HBAKInputConnection alloc] initWithNode:self bus:(int)bus];
}

@end

@implementation HBAKConnection

@end
