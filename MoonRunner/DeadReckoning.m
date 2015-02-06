//
//  DeadReckoning.m
//  MoonRunner
//
//  Created by Youwen Yi on 2/2/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "DeadReckoning.h"
#import <stdlib.h>


#define kRadToDeg   57.2957795

#define stepLen 0.50 //unit: meters

#define alphaTracker 0.23 //smoothing factor, cutoff frequency 3Hz

#define stepDetectThreshold 0.08 //step detection threshold

#define macroAxis  6378137 //the radius of equator

#define microAxis  6356752 //the half distance between north and sourth poles

#define particleNum 100 //number of particles in particle filter

#define distanceThreshold 10 //unit: meters

#define resampleRatio 0.8 //resample ratio for particle filter


@implementation DeadReckoning{

    double _lastDirection;
    
    int _lastStep;
    
    int _currentStep;
    
    double _lastGravity;
    
    CGPoint _startPointBuffer;
    
    double _stepLens[particleNum];
    
    double _directions[particleNum];
    
    CGPoint _positions[particleNum];
    
    double _particleWeight[particleNum];
    
}

-(void)startSensorReading{
    
    //initialization
    _lastStep = 1;
    _lastDirection = 0;
    _lastGravity = 0;
    _startPointBuffer = CGPointZero;
    
    for (int i=0; i<particleNum; i++) {
        
        _stepLens[i] = stepLen + (arc4random()%100)/10;
        
        _particleWeight[i] = 1.0/particleNum;
        
    }
    
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
        _gravity = [self smoothing:_gravity lastData:_lastGravity];
    }
    _lastGravity = _gravity;
    
    if (_gravity >= stepDetectThreshold) {
        _currentStep = 1;
        
    } else {
        _currentStep = 0;
        
    }
    
    if ((_currentStep - _lastStep) == 1) {
        _stepCount++;
        
        //estimate the next step
        if (!CGPointEqualToPoint(_startPoint, CGPointZero)) {
            
            if ( CGPointEqualToPoint(_startPoint, _startPointBuffer)) {//no gps update
                
                [self locationParticleFilter:NO directionData:directionData];
                
            }else{//with gps update
                
                [self locationParticleFilter:YES directionData:directionData];
                
                _startPointBuffer = _startPoint;
                
            }
        }
        
    }
    
    _lastStep = _currentStep;
    
    return _stepCount;
}


-(double)smoothing:(double)rawData
          lastData:(double)lastData{
    
    double smoothedData = alphaTracker*rawData + (1-alphaTracker)*lastData;
    
    return smoothedData;
    
}

-(void)locationParticleFilter:(BOOL)locationUpdated directionData:(double)directionData{

    if (locationUpdated) {
        
        double weightBuffer = 0;
        for (int i=0; i<particleNum; i++) {
            
            double distance = sqrt(pow(_positions[i].x - _startPoint.x, 2)+pow(_positions[i].y - _startPoint.y, 2));
            
            if (distance > distanceThreshold) {
                _particleWeight[i] = 0;
                
            } else {
                weightBuffer += _particleWeight[i];
                
            }
        }
        
        if (weightBuffer == 0) {// all the particles should be resampled
            CGPoint newPoint = CGPointZero;
            
            for (int i=0; i<particleNum; i++) {
                
                //step length, random, 10 meters
                _stepLens[i] = stepLen + (arc4random()%100)/10;
                
                _particleWeight[i] = 1.0/particleNum;
                
                //direction, random, 7 degree (uniform first)
//                _directions[i] = directionData + (arc4random()%7)/kRadToDeg;
                _directions[i] = directionData;
                
                _positions[i].x = _startPoint.x + _stepLens[i]/_mapMeterPerPixel*cos(_directions[i]);
                _positions[i].y = _startPoint.y + _stepLens[i]/_mapMeterPerPixel*sin(_directions[i]);
                
                newPoint.x += _particleWeight[i]*_positions[i].x;
                newPoint.y += _particleWeight[i]*_positions[i].y;
            }
            
            [_positionData addObject:[NSValue valueWithCGPoint:newPoint]];
            
            
        } else {//possible for resampling
            
            //determine whether resample needed
            _particleWeight[0] = _particleWeight[0]/weightBuffer;
            
            double pfEfficiency = pow(_particleWeight[0], 2);
            
            double cumWeight[particleNum];
            cumWeight[0] = _particleWeight[0];
            
            CGPoint positionBuffer[particleNum];
            positionBuffer[0] = _positions[0];
            
            for (int i=1; i<particleNum; i++) {
                
                //update the particle weight
                _particleWeight[i] = _particleWeight[i]/weightBuffer;
                
                //calculate the efficiency
                pfEfficiency += pow(_particleWeight[i], 2);
                
                //calculate the cumulative probability
                cumWeight[i] = cumWeight[i-1] + _particleWeight[i];
                
                //copy the positions for resampling
                positionBuffer[i] = _positions[i];
            }
            
            pfEfficiency = 1.0/pfEfficiency;
            
            if (pfEfficiency < particleNum*resampleRatio) {//resample needed
                
                CGPoint newPoint;
                
                int indexNum = 0;
                
                for (int i=0; i<particleNum; i++) {
                    
                    //generate a random number in (0,1);
                    double randNum = arc4random()/RAND_MAX;
                    
                    //find j such that cumWeight[j-1] < randNum < cumWeight[j]
                    int j = 0;
                    while (j < particleNum) {
                        if (randNum < cumWeight[j]) {
                            indexNum = j;
                            
                            break;
                        }
                        
                        j++;
                    }
                    
                    _stepLens[i] = _stepLens[indexNum];
                    
                    _positions[i] = positionBuffer[indexNum];
                    
                    _particleWeight[i] = 1.0/particleNum;
                    
                    
                    //direction, random, 7 degree (uniform first)
//                    _directions[i] = directionData + (arc4random()%7)/kRadToDeg;
                    _directions[i] = directionData;
                    
                    _positions[i].x += _stepLens[i]/_mapMeterPerPixel*cos(_directions[i]);
                    _positions[i].y += _stepLens[i]/_mapMeterPerPixel*sin(_directions[i]);
                    
                    newPoint.x += _particleWeight[i]*_positions[i].x;
                    newPoint.y += _particleWeight[i]*_positions[i].y;
                
                }
                
                [_positionData addObject:[NSValue valueWithCGPoint:newPoint]];
                
                
            } else {
                
                CGPoint newPoint = CGPointZero;
                
                for (int i=0; i<particleNum; i++) {
                    
                    //direction, random, 7 degree (uniform first)
//                    _directions[i] = directionData + (arc4random()%7)/kRadToDeg;
                    _directions[i] = directionData;
                    
                    _positions[i].x += _stepLens[i]/_mapMeterPerPixel*cos(_directions[i]);
                    _positions[i].y += _stepLens[i]/_mapMeterPerPixel*sin(_directions[i]);
                    
                    newPoint.x += _particleWeight[i] * _positions[i].x;
                    newPoint.y += _particleWeight[i] * _positions[i].y;
                }
                
                [_positionData addObject:[NSValue valueWithCGPoint:newPoint]];
                
            }
            
        }
        
        
    } else {// no gps update, dead reckoning continue
        
        CGPoint newPoint = CGPointZero;
        
        for (int i=0; i<particleNum; i++) {
            
            //direction, random, 7 degree (uniform first)
//            _directions[i] = directionData + (arc4random()%7)/kRadToDeg;
            _directions[i] = directionData;
            
            _positions[i].x += _stepLens[i]/_mapMeterPerPixel*cos(_directions[i]);
            _positions[i].y += _stepLens[i]/_mapMeterPerPixel*sin(_directions[i]);
            
            newPoint.x += _particleWeight[i] * _positions[i].x;
            newPoint.y += _particleWeight[i] * _positions[i].y;
        }
        
        [_positionData addObject:[NSValue valueWithCGPoint:newPoint]];

    }

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
