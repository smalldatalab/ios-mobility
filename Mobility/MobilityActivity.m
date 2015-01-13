//
//  MobilityActivity.m
//  Mobility
//
//  Created by Charles Forkish on 12/29/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityActivity.h"


@implementation MobilityActivity

@dynamic confidence;
@dynamic timestamp;
@dynamic uuid;
@dynamic userEmail;
@dynamic stationary;
@dynamic walking;
@dynamic running;
@dynamic automotive;
@dynamic cycling;
@dynamic unknown;
@dynamic submitted;

@synthesize activitiesArray=_activitiesArray;

+ (NSString *)stringForActivityType:(MobilityActivityType)activityType
{
    switch (activityType) {
        case MobilityActivityTypeStill:
            return @"still";
        case MobilityActivityTypeWalk:
            return @"walk";
        case MobilityActivityTypeRun:
            return @"run";
        case MobilityActivityTypeTransport:
            return @"transport";
        case MobilityActivityTypeCycle:
            return @"cycle";
        default:
            return @"unknown";
    }
}

+ (MobilityActivityType)typeForActivityString:(NSString *)activityString
{
    if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeStill]]) {
        return MobilityActivityTypeStill;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeWalk]]) {
        return MobilityActivityTypeWalk;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeRun]]) {
        return MobilityActivityTypeRun;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeTransport]]) {
        return MobilityActivityTypeTransport;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeCycle]]) {
        return MobilityActivityTypeCycle;
    }
    else {
        return MobilityActivityTypeUnknown;
    }
}

+ (NSString *)stringForConfidence:(CMMotionActivityConfidence)confidence
{
    switch (confidence) {
        case CMMotionActivityConfidenceLow:
            return @"low";
        case CMMotionActivityConfidenceMedium:
            return @"medium";
        case CMMotionActivityConfidenceHigh:
            return @"high";
        default:
            return nil;
    }
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.uuid = [[[NSUUID alloc] init] UUIDString];
}

- (void)didTurnIntoFault
{
    _activitiesArray = nil;
}

- (NSArray *)activitiesArray
{
    if (_activitiesArray == nil) {

        NSMutableArray *array = [NSMutableArray array];
        
        if (self.stationary) {
            [array addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeStill],
                                         @"confidence" : self.confidenceString}];
        }
        if (self.walking) {
            [array addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeWalk],
                                         @"confidence" : self.confidenceString}];
        }
        if (self.running) {
            [array addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeRun],
                                         @"confidence" : self.confidenceString}];
        }
        if (self.automotive) {
            [array addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeTransport],
                                         @"confidence" : self.confidenceString}];
        }
        if (self.cycling) {
            [array addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeCycle],
                                         @"confidence" : self.confidenceString}];
        }
        if (self.unknown || array.count == 0) {
            [array addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeUnknown],
                                         @"confidence" : self.confidenceString}];
        }
        
        
//        if (self.unknown) {
//            [array addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeUnknown],
//                               @"confidence" : self.confidenceString}];
//        }
//        
//        if (array.count == 0) {
//            [array addObject:@{@"activity" : @"\"unknown\"",
//                               @"confidence" : self.confidenceString}];
//        }
        
        _activitiesArray = array;
    }
    return _activitiesArray;
}

- (NSString *)debugActivityString
{
    NSMutableString *text = [NSMutableString string];
    MobilityActivityDictionary *activity;
    for (int i = 0; i < self.activitiesArray.count; i++) {
        if (i > 0) [text appendString:@", "];
        activity = self.activitiesArray[i];
        [text appendString:activity.activityString];
    }
    
    return text;
}

- (NSString *)confidenceString
{
    return [MobilityActivity stringForConfidence:self.confidence];
}

- (NSMutableDictionary *)jsonDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:self.activitiesArray forKey:@"activities"];
    return dictionary;
}

@end


#pragma mark - MobilityActivityDictionary

@implementation NSDictionary (MobilityActivityDictionary)

- (MobilityActivityType)activityType
{
    return [MobilityActivity typeForActivityString:self.activityString];
}

- (NSString *)activityString
{
    return self[@"activity"];
}

- (NSString *)confidence
{
    return self[@"confidence"];
}

@end
