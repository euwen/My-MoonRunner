//
//  DeadReckoning.h
//  MoonRunner
//
//  Created by Youwen Yi on 2/2/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@class DeadReckoning;
@protocol DeadReckoningDelegate <NSObject>

@optional
-(void)dataUpdating:(NSMutableArray *)positionData
      timestampData:(NSMutableArray *)timestamp
            magData:(CMMagnetometerData*)magData
         motionData:(CMDeviceMotion*)motion;

@optional
-(void)locationUpdating:(NSMutableArray *)positionData
          timestampData:(NSMutableArray *)timestamps;

@optional
-(void)positionUpdating:(CGPoint )newPosition;

@end


@interface DeadReckoning : NSObject <CLLocationManagerDelegate>

@property(weak,nonatomic) id <DeadReckoningDelegate> delegate;

@property(nonatomic, strong) CMMotionManager *motionManager;

@property(nonatomic, strong) CLLocationManager *locationManger;

@property(nonatomic, strong) NSMutableArray *positionData;

@property(nonatomic, strong) NSMutableArray *timestamps;

@property(nonatomic, strong) CMPedometer *pedometer;

@property(nonatomic, strong) CMDeviceMotion *motionData;

@property(nonatomic, strong) CMMagnetometerData *magData;

//@property(nonatomic) double stepLen;

@property(nonatomic) double mapMeterPerPixel;

@property(nonatomic) int stepCount;

@property(nonatomic) UIDevice *device;

@property(nonatomic) double currentDirection;

@property(nonatomic) NSNumber *pedometerSteps;

@property(nonatomic) CGPoint startPoint;

@property(nonatomic) double mapNorthOffset;

@property(nonatomic) CGPoint newPosition;

-(void)startSensorReading;

-(void)stopSensorReading;

@end
