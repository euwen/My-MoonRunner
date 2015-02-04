//
//  MathController.h
//  MoonRunner
//
//  Created by Youwen Yi on 1/19/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Location.h"
#import "MulticolorPolylineSegment.h"

@interface MathController : NSObject

+(NSString *)stringifyDistance:(float)meters;
+(NSString *)stringifySecondCount:(int)seconds usingLongFormat:(BOOL)longFormat;
+(NSString *)stringifyAvgPaceFromDist:(float)meters overTime:(int)seconds;

+ (NSArray *)colorSegmentsForLocations:(NSArray *)locations;

@end
