//
//  HBAKDevice.m
//  ProtonCrew
//
//  Created by HolidayBomb on 2021/12/3.
//  Copyright © 2021 ProtonCrew. All rights reserved.
//

#import "HBAKDevice.h"
#import "HBAudioSession.h"

@implementation HBAKDevice

- (instancetype)initWithName:(NSString *)name deviceID:(NSString *)deviceID dataSource:(NSString *)dataSource {
    if (self = [super init]) {
        self.name = name;
        self.deviceID = deviceID;
        if (dataSource.length > 0) {
            self.deviceID = [NSString stringWithFormat:@"%@ %@", deviceID, dataSource];
        }
    }
    return self;
}

- (instancetype)initWithPortescription:(AVAudioSessionPortDescription *)portDescription {
    if (self = [self initWithName:portDescription.portName deviceID:portDescription.UID dataSource:portDescription.selectedDataSource.dataSourceName]) {
        
    }
    return self;
}

- (AVAudioSessionPortDescription *)portDescription {
    return [[AVAudioSession sharedInstance].availableInputs hb_filterElements:^BOOL(AVAudioSessionPortDescription * _Nonnull elemtent) {
        return [elemtent.portName isEqualToString:self.name];
    }].firstObject;
}

- (AVAudioSessionDataSourceDescription *)dataSource {
    return [[self portDescription].dataSources hb_filterElements:^BOOL(AVAudioSessionDataSourceDescription * _Nonnull elemtent) {
        return [self.deviceID containsString:elemtent.dataSourceName];
    }].firstObject;
}

@end
