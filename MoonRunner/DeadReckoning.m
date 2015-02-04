//
//  DeadReckoning.m
//  MoonRunner
//
//  Created by Youwen Yi on 2/2/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "DeadReckoning.h"

#define kRadToDeg   57.2957795

#define stepLen 0.60 //unit: meters

#define alphaTracker 0.23 //smoothing factor, cutoff frequency 3Hz

#define stepDetectThreshold 0.08 //step detection threshold

#define macroAxis = 6378137 //the radius of equator

#define microAxis = 6356752 //the half distance between north and sourth poles


@implementation DeadReckoning{

    double _lastDirection;
    double _lastStep;
    
    double _lastGravity;
}

-(void)startSensorReading{
    
    //initialization
    _lastStep = 1;
    _lastDirection = 0;
    _lastGravity = 0;
    
    _positionData = [[NSMutableArray alloc] init];
    
    _motionManager = [[CMMotionManager alloc]init];
    
    //heading
    _locationManger = [[CLLocationManager alloc]init];
    _locationManger.delegate = self;
    
    if ([CLLocationManager headingAvailable]) {
        _locationManger.headingFilter = 1; //unit:degree;
        [_locationManger startUpdatingHeading];
        
    }
    
    //device motion
    _motionManager.magnetometerUpdateInterval = 0.1;
    [_motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData *magData, NSError *error) {
        if (error) {
            NSLog(@"Magnetometer Error: %@", error);
            
        } else {
            [self outputMagData:magData];
        }
    }];
    
    
    _motionManager.deviceMotionUpdateInterval = 0.1;
    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error){
        if (error ) {
            NSLog(@"Motion Error: %@", error);
            
        }else{
            
            [self outputMotionData:motion];
            
        }
        
    }];
    
    /*
     _device = [UIDevice currentDevice];
     [_device beginGeneratingDeviceOrientationNotifications];
     
     [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(deviceOrientaionDidChange)
     name:UIDeviceOrientationDidChangeNotification
     object:nil];*/
    
    //_pedometer = [[CMPedometer alloc]init];

}


-(void)stopSensorReading{

    [_motionManager stopDeviceMotionUpdates];
    [_motionManager stopMagnetometerUpdates];
    [_locationManger stopUpdatingHeading];

}


-(void)locationManager:(CLLocationManager *)manager
      didUpdateHeading:(CLHeading *)newHeading{
    
    if (newHeading.headingAccuracy < 0) {
        return;
    }
    
    CLLocationDirection theHeading = ((newHeading.trueHeading > 0) ?
                                      newHeading.trueHeading:newHeading.magneticHeading);
    
    
    //for indoor map
//    _currentDirection = (theHeading-90)/kRadToDeg;
    
    //for outdoor map
    _currentDirection = (theHeading-90)/kRadToDeg;
    
    //avoid the direction jump from 0 to 2pi or 2pi to 0
    if (_lastDirection != 0 && fabs(_currentDirection - _lastDirection) < M_PI) {
        _currentDirection = [self smoothing:_currentDirection lastData:_lastDirection];
    }
    
    _lastDirection = _currentDirection;
}


-(void)outputMotionData:(CMDeviceMotion *)motion{
    
    _motionData = motion;
    
    //step count
    [self stepCount:motion.userAcceleration gravityInfo:motion.gravity directionInfo:_currentDirection];
    
    [self.delegate dataUpdating:_positionData magData:_magData motionData:_motionData];
    
}


-(void)outputMagData:(CMMagnetometerData *)magData{
    
    //NSLog(@"direciton: %f", magData.magneticField.x);
    //_currentDirection = (magData.magneticField.y+90)/kRadToDeg;
    
    _magData = magData;
}


-(int)stepCount:(CMAcceleration)userAccData
    gravityInfo:(CMAcceleration)gravityData
  directionInfo:(double)directionData{
    
    //double _gravity = sqrt(pow(userAccData.x, 2) + pow(userAccData.y, 2) + pow(userAccData.z, 2));
    
    //use the accelaration only in the gravity direction
    double _gravity = (gravityData.x*userAccData.x + gravityData.y*userAccData.y + gravityData.z*userAccData.z);
    
    if (_lastGravity != 0) {
        [self smoothing:_gravity lastData:_lastGravity];
    }
    _lastGravity = _gravity;
    
    if (_gravity >= stepDetectThreshold) {
        _gravity = 1;
        
    } else {
        _gravity = 0;
        
    }
    
    if ((_gravity - _lastStep) == 1) {
        _stepCount++;
        
        //estimate the next step
        
        CGPoint endPoint;
        
        if ( !CGPointEqualToPoint(_startPoint, CGPointZero) ) {
            
            endPoint.x = _startPoint.x + stepLen/_mapMeterPerPixel*cos(directionData);
            endPoint.y = _startPoint.y + stepLen/_mapMeterPerPixel*sin(directionData);
            
            [_positionData addObject:[NSValue valueWithCGPoint:endPoint]];
            
            _startPoint = endPoint;
        }
        
    }
    
    _lastStep = _gravity;
    
    return _stepCount;
}


-(double)smoothing:(double)rawData
          lastData:(double)lastData{
    
    double smoothedData = alphaTracker*rawData + (1-alphaTracker)*lastData;
    
    return smoothedData;
    
}

 -(void)deviceOrientaionDidChange{
 
     _device = [UIDevice currentDevice];
 
     switch (_device.orientation) {
        case UIDeviceOrientationUnknown:
            NSLog(@"Unknown!");
             break;
 
        case UIDeviceOrientationFaceUp:
             NSLog(@"Face up!");
             break;
 
         case UIDeviceOrientationFaceDown:
             NSLog(@"Face down!");
             break;
 
         case UIDeviceOrientationLandscapeLeft:
             NSLog(@"Home button right!");
             break;
 
         case UIDeviceOrientationLandscapeRight:
             NSLog(@"Home button left!");
             break;
 
         case UIDeviceOrientationPortrait:
             NSLog(@"Home button bottom!");
             break;
 
         case UIDeviceOrientationPortraitUpsideDown:
             NSLog(@"Home button top!");
             break;
 
         default:
             NSLog(@"Cannot distinguish!");
             break;
     }
 
 }

@end
