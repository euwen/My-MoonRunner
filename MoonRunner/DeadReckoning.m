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

#define stepDetectThreshold 0.05 //step detection threshold

#define macroAxis  6378137 //the radius of equator

#define microAxis  6356752 //the half distance between north and sourth poles

#define particleNum 100 //number of particles in particle filter

#define distanceThreshold 20 //unit: meters

#define resampleRatio 0.8 //resample ratio for particle filter


@implementation DeadReckoning{
   
    int _lastStep;
    
    int _currentStep;
    
    double _lastGravity;
    
    double _lastDirection;
    
    // for particle filter
    CGPoint _startPointBuffer;
    
    double _stepLens[particleNum];
    
    double _directions[particleNum];
    
    CGPoint _positions[particleNum];
    
    double _particleWeight[particleNum];
    
    CMAttitude *referenceAttitude;
    
}

-(void)startSensorReading{
    
    //initialization
    _lastStep = 1;
    _lastDirection = 0;
    _lastGravity = 0;
    _startPointBuffer = CGPointZero;
    
    _positionData = [[NSMutableArray alloc] init];
    _timestamps = [[NSMutableArray alloc] init];
    
    for (int i=0; i<particleNum; i++) {
        
        _stepLens[i] = stepLen + 2*arc4random()/RAND_MAX-1;
        
        _particleWeight[i] = 1.0/particleNum;
        
        _positions[i] = _startPoint;
        
    }
    
    //heading
    _locationManger = [[CLLocationManager alloc]init];
    _locationManger.delegate = self;
    
    if ([CLLocationManager headingAvailable]) {
        _locationManger.headingFilter = 1; //unit:degree;
        [_locationManger startUpdatingHeading];
        
    }
    
    //device motion
    _motionManager = [[CMMotionManager alloc]init];
    
    //mag data
    _motionManager.magnetometerUpdateInterval = 0.1;
    [_motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData *magData, NSError *error) {
        if (error) {
            NSLog(@"Magnetometer Error: %@", error);
            
        } else {
            [self outputMagData:magData];
        }
    }];
    
    //motion data
    CMDeviceMotion *deviceMotion = _motionManager.deviceMotion;
    referenceAttitude = deviceMotion.attitude;
    
    _motionManager.deviceMotionUpdateInterval = 0.1;
    
    //with attitude reference frame
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
                                                        toQueue:[NSOperationQueue currentQueue]
                                                    withHandler:^(CMDeviceMotion *motion, NSError *error) {
        if (error ) {
            NSLog(@"Motion Error: %@", error);
            
        }else{
            
            [self outputMotionData:motion];
            
        }
    }];
    
//    //without attitude reference frame
//    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error){
//        if (error ) {
//            NSLog(@"Motion Error: %@", error);
//            
//        }else{
//            
//            [self outputMotionData:motion];
//            
//        }
//        
//    }];
    
    _pedometer = [[CMPedometer alloc]init];
    [_pedometer startPedometerUpdatesFromDate:[NSDate date]
                                  withHandler:^(CMPedometerData *pedometerData, NSError *error) {
                                      if (error) {
                                          NSLog(@"Pedometer Error: %@", error);
                                      } else {
                                          [self outputPedoData:pedometerData];
                                      }
                                  }];

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
    
//    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//    switch (orientation) {
//        case UIDeviceOrientationPortrait:
//            break;
//            
//        case UIDeviceOrientationPortraitUpsideDown:
//            theHeading += 180.0;
//            break;
//            
//        case UIDeviceOrientationLandscapeLeft:
//            theHeading += 90.0;
//            break;
//            
//        case UIDeviceOrientationLandscapeRight:
//            theHeading -= 90.0;
//            break;
//            
//        default:
//            break;
//    }
    
//    float deviceAngle = atan2(_motionData.gravity.y, _motionData.gravity.x);
//    
//    if (deviceAngle >= -2.25 && deviceAngle <= -0.25) {
//        NSLog(@"Portrait");
//        
//    } else if(deviceAngle >= -1.75 && deviceAngle <= 0.75) {
//        theHeading -= 90.0;
//        NSLog(@"Landscape Right");
//        
//    } else if(deviceAngle >= 0.75 && deviceAngle <= 2.25){
//        theHeading += 180.0;
//        NSLog(@"Portrait Upside Down");
//    
//    }else if (deviceAngle <= -2.25 || deviceAngle >= 2.25){
//        theHeading += 90.0;
//        NSLog(@"Landscape Left");
//    
//    }
//    
//    while (theHeading > 360.0) {
//        theHeading -= 360;
//    }
    
    //for indoor map
    _currentDirection = (theHeading - 90 - _mapNorthOffset)/kRadToDeg;
    
    //for outdoor map
//    _currentDirection = (theHeading-90)/kRadToDeg;
    
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
    
    //optional, check first
    if ([self.delegate respondsToSelector:@selector(dataUpdating:timestampData:magData:motionData:)]) {
        [self.delegate dataUpdating:_positionData timestampData:_timestamps magData:_magData motionData:_motionData];
    }
    
}


-(void)outputMagData:(CMMagnetometerData *)magData{
    
    //NSLog(@"direciton: %f", magData.magneticField.x);
    //_currentDirection = (magData.magneticField.y+90)/kRadToDeg;
    
    _magData = magData;
}

-(void)outputPedoData:(CMPedometerData *)pedometerData{
    _stepCount = [pedometerData.numberOfSteps intValue];

}


-(int)stepCount:(CMAcceleration)userAccData
    gravityInfo:(CMAcceleration)gravityData
  directionInfo:(double)directionData{
    
    //double _gravity = sqrt(pow(userAccData.x, 2) + pow(userAccData.y, 2) + pow(userAccData.z, 2));
    
    //use the accelaration only in the gravity direction
    double _gravity = (gravityData.x*userAccData.x + gravityData.y*userAccData.y + gravityData.z*userAccData.z);
    
//    if (_lastGravity != 0) {
//        _gravity = [self smoothing:_gravity lastData:_lastGravity];
//    }
    _lastGravity = _gravity;
    
    if (_gravity >= stepDetectThreshold) {
        _currentStep = 1;
        
    } else {
        _currentStep = 0;
        
    }
    
    if ((_currentStep - _lastStep) == 1) {
        
        
        //for debug
        //_stepCount++;
        
        //estimate the next step
        if (!CGPointEqualToPoint(_startPoint, CGPointZero)) {
            
            if ( CGPointEqualToPoint(_startPoint, _startPointBuffer)) {//no gps/BLE update
                
                [self locationParticleFilter:NO directionData:directionData];
                
            }else{//with gps/BLE update
                
                [self locationParticleFilter:YES directionData:directionData];
                
                _startPointBuffer = _startPoint;
                
            }
            
            //optional, check first
            if ([self.delegate respondsToSelector:@selector(locationUpdating:timestampData:)]) {
                [self.delegate locationUpdating:_positionData timestampData:_timestamps];
            }
            
            //optional, check first
            if ([self.delegate respondsToSelector:@selector(positionUpdating:)]) {
                [self.delegate positionUpdating:_newPosition];
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

    if (locationUpdated) {// with gps/BLE location update
        
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
                _stepLens[i] = stepLen + 2*arc4random()/RAND_MAX-1;
                
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
            [_timestamps addObject:[NSDate date]];
            
            
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
                [_timestamps addObject:[NSDate date]];
                
                
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
                [_timestamps addObject:[NSDate date]];
                
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
        [_timestamps addObject:[NSDate date]];

    }

}

-(double)gaussianRandomNumber:(double)mean
                 stdVariance:(double)var{

    double randNum = 0.0;
    
    //method 1: use the central limit theorem
    double sum = 0.0;

    for (int i=0; i<12; i++) {
        sum = sum + arc4random()/RAND_MAX;
    }
    
    randNum = (sum - 6.0)*var + mean;
    
//    //method 2: use the reverse function
//    
//    double randNum1 = arc4random()/RAND_MAX;
//    double randNum2 = arc4random()/RAND_MAX;
//    
//    randNum = sqrt(-2.0*log(randNum1))*cos(2.0*M_PI*randNum2)*var + mean;
    
    return randNum;

}

@end
