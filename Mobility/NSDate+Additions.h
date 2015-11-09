//
//  NSDate+CPT.h
//  ohmage_ios
//
//  Created by Charles Forkish on 5/8/14.
//  Copyright (c) 2014 VPD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Additions)

+ (NSDate *)randomTimeTodayBetweenStartTime:(NSDate *)startTime endTime:(NSDate *)endTime;
+ (NSDate *)endOfDayToday;
+ (NSDate *)timeOfDayWithHours:(NSInteger)hours minutes:(NSInteger)minutes;

- (NSString *)ISO8601String;
- (NSString *)formattedDate;
- (NSString *)stringWithFormat_MMM_d_h_m_s;
- (NSString *)stringWithFormatTemplate:(NSString *)formatTemplate;

- (NSDate *)dateByAddingMonths:(NSInteger)months;
- (NSDate *)dateByAddingWeeks:(NSInteger)weeks;
- (NSDate *)dateByAddingWeekdays:(NSInteger)weekdays;
- (NSDate *)dateByAddingDays:(NSInteger)days;
- (NSDate *)dateByAddingHours:(NSInteger)hours;
- (NSDate *)dateByAddingMinutes:(NSInteger)minutes;
- (NSDate *)dateByAddingMonths:(NSInteger)months
                         weeks:(NSInteger)weeks
                      weekdays:(NSInteger)weekdays
                          days:(NSInteger)days
                         hours:(NSInteger)hours
                       minutes:(NSInteger)minutes;

- (NSDate *)dateWithTimeFromDate:(NSDate *)timeDate;
- (NSDate *)sameTimeToday;
- (NSInteger)weekdayComponent;

- (BOOL)isBeforeDate:(NSDate *)date;
- (BOOL)isAfterDate:(NSDate *)date;
- (BOOL)isToday;
- (BOOL)isEqualToDayOfDate:(NSDate *)date;

@end
