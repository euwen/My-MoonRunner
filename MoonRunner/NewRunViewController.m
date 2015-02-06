//
//  NewRunViewController.m
//  MoonRunner
//
//  Created by Youwen Yi on 1/19/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "NewRunViewController.h"
#import "DetailViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MathController.h"
#import "Location.h"
#import "Run.h"
#import "DeadReckoning.h"

static NSString * const detailSegueName = @"RunDetails";

@interface NewRunViewController ()<UIActionSheetDelegate, CLLocationManagerDelegate, MAMapViewDelegate, DeadReckoningDelegate>{

    MAMapView *_mapView;
    DeadReckoning *_deadReckoning;

}

@property int seconds;
@property float distance;
//@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *locations;
@property (strong, nonatomic) NSTimer *timer;

@property(strong, nonatomic) Run *run;

@property(nonatomic, weak)IBOutlet UILabel *promptLabel;
@property(nonatomic, weak)IBOutlet UILabel *timeLabel;
@property(nonatomic, weak)IBOutlet UILabel *distLabel;
@property(nonatomic, weak)IBOutlet UILabel *paceLabel;
@property(nonatomic, weak)IBOutlet UIButton *startButton;
@property(nonatomic, weak)IBOutlet UIButton *stopButton;

@end

@implementation NewRunViewController

-(void)viewWillAppear:(BOOL)animated{

    //show the start UI
    [super viewWillAppear:animated];
    self.startButton.hidden = NO;
    self.promptLabel.hidden = NO;
    
    //hide the running UI
    self.timeLabel.text = @"";
    self.timeLabel.hidden = YES;
    self.distLabel.hidden = YES;
    self.paceLabel.hidden = YES;
    self.stopButton.hidden = YES;

}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    //[MAMapServices sharedServices].apiKey = @"4fe484996ceb60d3e2b7ee03f7280d68";
    
    //show the map
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 200, CGRectGetWidth(self.view.bounds), 288)];
    _mapView.delegate = self;
    
    _mapView.hidden = YES;
    [self.view addSubview:_mapView];
    
    //initialize the delegate
    _deadReckoning = [[DeadReckoning alloc]init];
    _deadReckoning.delegate = self;
    
    _deadReckoning.mapMeterPerPixel = 1;
    _deadReckoning.startPoint = CGPointZero;
    
}

/*
-(void)startLocationUpdate{

    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        
//        //fix ios8 problem
//        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
//#ifdef _IPHONE_8_0
//            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
//                [self.locationManager performSelector:@selector(requestAlwaysAuthorization)];
//            }
//            
//            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
//                [self.locationManager performSelector:@selector(requestWhenInUseAuthorization)];
//            }
//#endif
//        }
//
//        
//    }
 
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //for dead reckoning
    //self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    self.locationManager.activityType = CLActivityTypeFitness;
    
    
    //movement threshold for new events
    self.locationManager.distanceFilter = 100;
    
    NSLog(@"authorization: %d", [CLLocationManager authorizationStatus]);
    
    [self.locationManager startUpdatingLocation];

}*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)startPressed:(id)sender{

    //hide the start UI
    self.startButton.hidden = YES;
    self.promptLabel.hidden = YES;
    
    //show the ruuning UI
    self.timeLabel.hidden = NO;
    self.distLabel.hidden = NO;
    self.paceLabel.hidden = NO;
    self.stopButton.hidden = NO;
    
    self.seconds = 0;
    self.distance = 0;
    self.locations = [NSMutableArray array];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(eachSecond)
                                                userInfo:nil
                                                 repeats:YES];
    
    _mapView.hidden = NO;
    _mapView.showsUserLocation = YES;
    
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    
    _mapView.desiredAccuracy = kCLLocationAccuracyBest;
    
    _mapView.distanceFilter = 100;
    
//    [self startLocationUpdate];
    
    [_deadReckoning startSensorReading];
    
}

-(IBAction)stopPressed:(id)sender{
    
    //get data from dead reckoning
    [_deadReckoning stopSensorReading];
    NSMutableArray *positions = [[NSMutableArray alloc] init];
    
    if (_deadReckoning.positionData.count > 0) {
        for (int i=0; i<_deadReckoning.positionData.count; i++) {
            CGPoint point = [[_deadReckoning.positionData objectAtIndex:i] CGPointValue];
            
            MAMapPoint mapPoint;
            mapPoint.x = point.x;
            mapPoint.y = point.y;
            
            CLLocationCoordinate2D coords = MACoordinateForMapPoint(mapPoint);
            
            CLLocation *location = [[CLLocation alloc] initWithLatitude:coords.latitude longitude:coords.longitude];
            
            [positions addObject:location];
            
        }
        self.locations = positions;
    }
    
    //save the data
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Save",@"Discard",nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];

}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{

    //[self.locationManager stopUpdatingLocation];
    
    //save
    if (buttonIndex == 0) {
        [self saveRun];
        [self performSegueWithIdentifier:detailSegueName sender:nil];
        
    } else if(buttonIndex == 1){//discard
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    
}

-(void)eachSecond{
    
    self.seconds++;
    self.timeLabel.text = [NSString stringWithFormat:@"Time: %@", [MathController stringifySecondCount:self.seconds usingLongFormat:NO]];
    self.distLabel.text = [NSString stringWithFormat:@"Distance: %@", [MathController stringifyDistance:self.distance]];
    self.paceLabel.text = [NSString stringWithFormat:@"Pace: %@", [MathController stringifyAvgPaceFromDist:self.distance overTime:self.seconds]];
    
}

/*
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{

    for(CLLocation *newLocation in locations){
        NSLog(@"Lat: %f, Lng: %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
        
        NSDate *eventDate = newLocation.timestamp;
        
        NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
        
        NSLog(@"%f", newLocation.horizontalAccuracy) ;
        
        if (abs(howRecent)<10 && newLocation.horizontalAccuracy < 100) {
            
            //update distance
            if (self.locations.count > 0) {
                self.distance += [newLocation distanceFromLocation:self.locations.lastObject];
                
                CLLocationCoordinate2D coords[2];
                coords[0] = ((CLLocation *)self.locations.lastObject).coordinate;
                coords[1] = newLocation.coordinate;
                
                MACoordinateRegion region = MACoordinateRegionMakeWithDistance(newLocation.coordinate, 500, 500);
                [_mapView setRegion:region animated:YES];
                
                [_mapView addOverlay:[MAPolyline polylineWithCoordinates:coords count:2]];
            }
        }
        [self.locations addObject:newLocation];
    
    }

}*/

-(void)dataUpdating:(NSMutableArray *)positionData magData:(CMMagnetometerData *)magData motionData:(CMDeviceMotion *)motion{

    //NSLog(@"Position Data: %@", positionData);

}


-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{

    if (updatingLocation) {
        NSLog(@"Lat: %f, Lng: %f", userLocation.coordinate.latitude, userLocation.coordinate.longitude);
        
        //update distance
        if (self.locations.count > 0) {
            self.distance += [userLocation.location distanceFromLocation:self.locations.lastObject];
            
            CLLocationCoordinate2D coords[2];
            coords[0] = ((CLLocation *)self.locations.lastObject).coordinate;
            coords[1] = userLocation.coordinate;
            
            MACoordinateRegion region = MACoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500);
            [_mapView setRegion:region animated:YES];
            
            [_mapView addOverlay:[MAPolyline polylineWithCoordinates:coords count:2]];
            
        }
        
        [self.locations addObject:userLocation.location];
        
        //for dead reckoning, use the Mercator projection
        MAMapPoint point = MAMapPointForCoordinate(CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude));
        
        CGPoint _point;
        _point.x = point.x;
        _point.y = point.y;
        
        _deadReckoning.startPoint = _point;
        
//        if (MACircleContainsPoint(<#MAMapPoint point#>, <#MAMapPoint center#>, <#double radius#>)){}
        
    }

}

-(MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay{
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolyline *polyLine = (MAPolyline *)overlay;
        MAPolylineRenderer *aRender = [[MAPolylineRenderer alloc] initWithPolyline:polyLine];
        aRender.strokeColor = [UIColor blueColor];
        aRender.lineWidth = 3;
        return aRender;
    }

    return nil;
}

-(void)saveRun{

    Run *newRun = [NSEntityDescription insertNewObjectForEntityForName:@"Run"
                                                inManagedObjectContext:self.managedObjectContext];
    
    newRun.distance = [NSNumber numberWithFloat:self.distance];
    newRun.duration = [NSNumber numberWithInt:self.seconds];
    newRun.timestamp = [NSDate date];
    
    NSMutableArray *locationArray = [NSMutableArray array];
    
    for (CLLocation *location in self.locations) {
        Location *locationObject = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
        
//        locationObject.timestamp = location.timestamp;
        locationObject.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
        locationObject.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
        
        [locationArray addObject:locationObject];
    }
    
    newRun.locations = [NSOrderedSet orderedSetWithArray:locationArray];
    self.run = newRun;
    
    //save the context
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }else{
    
        NSLog(@"Dist: %f, Time: %i", self.distance, self.seconds);
    }

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    [[segue destinationViewController] setRun:self.run];
    
}

@end
