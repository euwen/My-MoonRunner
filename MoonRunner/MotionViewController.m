//
//  MotionViewController.m
//  MoonRunner
//
//  Created by Youwen Yi on 1/22/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "MotionViewController.h"
#import "SensorLive.h"
#import "LineView.h"
#import "DeadReckoning.h"

#include "MadgwickAHRS.h"

#define kRadToDeg   57.2957795

#define indoorMapMeterPerPixel 0.0814 //unit: meters/pixel

@interface MotionViewController ()<DeadReckoningDelegate>

@property (nonatomic , strong) SensorLive *refreshMoniterView;
@property (nonatomic , strong) SensorLive *translationMoniterView;

@end

@implementation MotionViewController{
    
    NSMutableArray *dataSource;
    
    NSTimer *_refreshPlotTimer;
    NSTimer *_translationPlotTimer;
    
    CGPoint _startPoint;
    
    UIImageView *_floorMapView;
    
    LineView *_lineView;
    
    NSMutableArray *_positionData;
    
    DeadReckoning *_deadReckoning;

}

//for curve view
- (SensorLive *)refreshMoniterView
{
    if (!_refreshMoniterView) {
        CGFloat xOffset = 10;
        _refreshMoniterView = [[SensorLive alloc] initWithFrame:CGRectMake(xOffset, 20, CGRectGetWidth(self.view.frame) - 2 * xOffset, 200)];
        _refreshMoniterView.backgroundColor = [UIColor blackColor];
       _refreshPlotTimer =  [NSTimer scheduledTimerWithTimeInterval:0.1
                                                             target:self
                                                           selector:@selector(timerRefreshPlot)
                                                           userInfo:nil
                                                            repeats:YES];
        
    }

    return _refreshMoniterView;
}

- (SensorLive *)translationMoniterView
{
    if (!_translationMoniterView) {
        CGFloat xOffset = 10;
        _translationMoniterView = [[SensorLive alloc] initWithFrame:CGRectMake(xOffset, CGRectGetMaxY(self.refreshMoniterView.frame) + 10, CGRectGetWidth(self.view.frame) - 2 * xOffset, 200)];
        _translationMoniterView.backgroundColor = [UIColor blackColor];
        _translationPlotTimer =  [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerTranslationPlot) userInfo:nil repeats:YES];
    }
    return _translationMoniterView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //
    //display map
    //
    _floorMapView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 64, 320, 320)];
    _floorMapView.image = [UIImage imageNamed:@"floorMap"];
    
    [self.view addSubview:_floorMapView];
    
    _startPoint = CGPointMake(234, 243);
    
    _positionData = [[NSMutableArray alloc]init];
    
    _lineView = [[LineView alloc]initWithFrame:self.view.frame];
    
    _lineView.rectHeight = CGRectGetHeight(_floorMapView.frame);
    
    //_lineView.startPoint = _startPoint;
    
    [_floorMapView addSubview:_lineView];
    
    
    self.sensorSwitch.backgroundColor = [UIColor blackColor];
    
    [self.sensorSwitch setOn:NO animated:YES];
    
    [self.sensorSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.title = @"Sensor Data";
    
    //self.view.backgroundColor = [UIColor lightGrayColor];
    
    dataSource = [[NSMutableArray alloc] init];
    
    //initialize the delegate
    _deadReckoning = [[DeadReckoning alloc]init];
    _deadReckoning.delegate = self;
    
    _deadReckoning.mapMeterPerPixel = indoorMapMeterPerPixel;
    _deadReckoning.startPoint = _startPoint;
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_translationPlotTimer invalidate];
    [_refreshPlotTimer invalidate];
    
    [_deadReckoning stopSensorReading];

}

-(void)switchValueChanged:(id)sender{
    UISwitch *controller = (UISwitch*) sender;
    if (controller == self.sensorSwitch) {
        if (controller.on) {
            [_deadReckoning startSensorReading];
            
       
        }else{
            [_deadReckoning stopSensorReading];
        
        }
    }

}

-(void)dataUpdating:(NSMutableArray *)positionData timestampData:(NSMutableArray *)timestamps magData:(CMMagnetometerData *)magData motionData:(CMDeviceMotion *)motion{

    //motion sensor data
    
    self.accLabel.text = [NSString stringWithFormat:@" Acceleration.x: %.2f\n Acceleration.y: %.2f\n Acceleration.z: %.2f", motion.gravity.x, motion.gravity.y, motion.gravity.z];
    
    
    self.gyroLabel.text = [NSString stringWithFormat:@" Gyroscope.x: %.2f\n Gyroscope.y: %.2f\n Gyroscope.z: %.2f", motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z];
    
    
    self.attLabel.text = [NSString stringWithFormat:@" Roll: %.2f\n Pitch: %.2f\n Yaw: %.2f", motion.attitude.roll*kRadToDeg, motion.attitude.pitch*kRadToDeg, motion.attitude.yaw*kRadToDeg];
    
    
    self.stepLabel.text = [NSString stringWithFormat:@" Step Count: %lu", (unsigned long)positionData.count];
    
//    //Quaternion to Eular angles
//    double wQuat = motion.attitude.quaternion.w;
//    double xQuat = motion.attitude.quaternion.x;
//    double yQuat = motion.attitude.quaternion.y;
//    double zQuat = motion.attitude.quaternion.z;
//    
//    double pitch = atan2(2*(wQuat*xQuat + yQuat*zQuat), 1-2*(xQuat*xQuat + yQuat*yQuat));
//    double roll = asin(2*(wQuat*yQuat - zQuat*xQuat));
//    double yaw = atan2(2*(wQuat*zQuat + xQuat*yQuat), 1-2*(yQuat*yQuat + zQuat*zQuat));
//    
//    self.gyroLabel.text = [NSString stringWithFormat:@" Roll: %.2f\n Pitch: %.2f\n Yaw: %.2f", roll*kRadToDeg, pitch*kRadToDeg, yaw*kRadToDeg];
    
    //rotaion matrix
    CMAttitude *deviceAttitude = motion.attitude;
    
    //    [deviceAttitude multiplyByInverseOfAttitude:referenceAttitude];
    
    CMRotationMatrix rotation = deviceAttitude.rotationMatrix;
    
    double gravityX = rotation.m11*motion.gravity.x + rotation.m12*motion.gravity.y + rotation.m13*motion.gravity.z;
    double gravityY = rotation.m21*motion.gravity.x + rotation.m22*motion.gravity.y + rotation.m23*motion.gravity.z;
    double gravityZ = rotation.m31*motion.gravity.x + rotation.m32*motion.gravity.y + rotation.m33*motion.gravity.z;
    
    self.gyroLabel.text = [NSString stringWithFormat:@" Gyroscope.x: %.2f\n Gyroscope.y: %.2f\n Gyroscope.z: %.2f", gravityX, gravityY, gravityZ];
    
    //magnetometer data
    
    self.magLabel.text = [NSString stringWithFormat:@" Magnetometer.x: %.2f\n Magnetometer.y: %.2f\n Magnetomerter.z: %.2f", magData.magneticField.x, magData.magneticField.y, magData.magneticField.z];
    
    _lineView.positionData = positionData;
    
    [_lineView setNeedsDisplay];
    
    MadgwickAHRSupdateIMU(motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z, motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - creat data source

//刷新方式绘制
- (void)timerRefreshPlot
{
    [[PointContainer sharedContainer] addPointAsRefreshChangeform:[self bubbleRefreshPoint]];
    
    [self.refreshMoniterView fireDrawingWithPoints:[PointContainer sharedContainer].refreshPointContainer pointsCount:[PointContainer sharedContainer].numberOfRefreshElements];
}

//平移方式绘制
- (void)timerTranslationPlot
{
    [[PointContainer sharedContainer] addPointAsTranslationChangeform:[self bubbleTranslationPoint]];
    
    [self.translationMoniterView fireDrawingWithPoints:[[PointContainer sharedContainer] translationPointContainer] pointsCount:[[PointContainer sharedContainer] numberOfTranslationElements]];
    
}

#pragma mark - DataSource

- (CGPoint)bubbleRefreshPoint
{
    static NSInteger dataSourceCounterIndex = -1;
    dataSourceCounterIndex ++;
    dataSourceCounterIndex %= [dataSource count];
    
    
    NSInteger pixelPerPoint = 1;
    static NSInteger xCoordinateInMoniter = 0;
    
    CGPoint targetPointToAdd = (CGPoint){xCoordinateInMoniter,[dataSource[dataSourceCounterIndex] integerValue] *1000};
    xCoordinateInMoniter += pixelPerPoint;
    xCoordinateInMoniter %= (int)(CGRectGetWidth(self.translationMoniterView.frame));
    
    //    NSLog(@"吐出来的点:%@",NSStringFromCGPoint(targetPointToAdd));
    return targetPointToAdd;
}

- (CGPoint)bubbleTranslationPoint
{
    static NSInteger dataSourceCounterIndex = -1;
    dataSourceCounterIndex ++;
    dataSourceCounterIndex %= [dataSource count];
    
    
    NSInteger pixelPerPoint = 1;
    static NSInteger xCoordinateInMoniter = 0;
    
    CGPoint targetPointToAdd = (CGPoint){xCoordinateInMoniter,[dataSource[dataSourceCounterIndex] integerValue] *1000};
    xCoordinateInMoniter += pixelPerPoint;
    xCoordinateInMoniter %= (int)(CGRectGetWidth(self.translationMoniterView.frame));
    
    //    NSLog(@"吐出来的点:%@",NSStringFromCGPoint(targetPointToAdd));
    return targetPointToAdd;
}

/*
// get the touch point as startpoint for walking
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    startPoint = [touch locationInView:floorMapView];
    
    NSLog(@"touch point: %f %f", startPoint.x, startPoint.y);

}*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
