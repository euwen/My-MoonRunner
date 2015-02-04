//
//  DetailViewController.m
//  MoonRunner
//
//  Created by Youwen Yi on 1/16/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "DetailViewController.h"
#import <MAMapKit/MAMapKit.h>
#import "MathController.h"
#import "Run.h"
#import "Location.h"
#import "MulticolorPolylineSegment.h"


@interface DetailViewController ()<MAMapViewDelegate>{

    MAMapView *_mapView;
}

@property(nonatomic, weak)IBOutlet UILabel *distanceLabel;
@property(nonatomic, weak)IBOutlet UILabel *dateLabel;
@property(nonatomic, weak)IBOutlet UILabel *timeLabel;
@property(nonatomic, weak)IBOutlet UILabel *paceLabel;

@property(nonatomic, strong) CLGeocoder *geocoder;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setRun:(Run *)run{
    if (_run != run) {
        _run = run;
            
        // Update the view.
        //[self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    self.distanceLabel.text = [MathController stringifyDistance:self.run.distance.floatValue];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    self.dateLabel.text = [formatter stringFromDate:self.run.timestamp];
    
    self.timeLabel.text = [NSString stringWithFormat:@" Time:\n %@", [MathController stringifySecondCount:self.run.duration.intValue usingLongFormat:YES]];
    
    //NSLog(@"Duration: %i",self.run.duration.intValue);
    
    self.paceLabel.text = [NSString stringWithFormat:@" Pace:\n %@", [MathController stringifyAvgPaceFromDist:self.run.distance.floatValue overTime:self.run.duration.intValue]];
    
    [self loadMap];

}

-(MACoordinateRegion)mapRegion{

    MACoordinateRegion region;
    Location *initialLoc = self.run.locations.firstObject;
    
    float minLat = initialLoc.latitude.floatValue;
    float minLng = initialLoc.longitude.floatValue;
    float maxLat = initialLoc.latitude.floatValue;
    float maxLng = initialLoc.longitude.floatValue;
    
    for (Location *location in self.run.locations) {
        if (location.latitude.floatValue < minLat) {
            minLat = location.latitude.floatValue;
        }
        
        if (location.longitude.floatValue < minLng) {
            minLng = location.longitude.floatValue;
        }
        
        if (location.latitude.floatValue > maxLat) {
            maxLat = location.latitude.floatValue;
        }
        
        if (location.longitude.floatValue > maxLng) {
            maxLng = location.longitude.floatValue;
        }
    }
    
    region.center.latitude = (minLat + maxLat)/2.0f;
    region.center.longitude = (minLng + maxLng)/2.0f;
    
    //10% padding
    region.span.latitudeDelta = (maxLat - minLat)*1.1f;
    region.span.longitudeDelta = (maxLng - minLng)*1.1f;
    
    return region;

}

-(MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay{

    /*
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolyline *polyLine = (MAPolyline *)overlay;
        MAPolylineRenderer *aRenderer = [[MAPolylineRenderer alloc] initWithPolyline:polyLine];
        aRenderer.strokeColor = [UIColor blackColor];
        aRenderer.lineWidth = 3;
        return aRenderer;
    }*/
    
    if ([overlay isKindOfClass:[MulticolorPolylineSegment class]]) {
        MulticolorPolylineSegment *polyLine = (MulticolorPolylineSegment *)overlay;
        MAPolylineRenderer *aRenderer = [[MAPolylineRenderer alloc] initWithPolyline:polyLine];
        aRenderer.strokeColor = polyLine.color;
        aRenderer.lineWidth = 3;
        return aRenderer;
    }
    
    return nil;
}

-(MAPolyline *)polyLine{

    CLLocationCoordinate2D coords[self.run.locations.count];
    
    for (int i=0; i<self.run.locations.count; i++) {
        Location *location = [self.run.locations objectAtIndex:i];
        coords[i] = CLLocationCoordinate2DMake(location.latitude.doubleValue, location.longitude.doubleValue );
    }

    return [MAPolyline polylineWithCoordinates:coords count:self.run.locations.count];
}

-(void)loadMap{
    if (self.run.locations.count > 0) {
        _mapView.hidden = NO;
        
        MACoordinateRegion region = [self mapRegion];
        
        //set the map bounds
        [_mapView setRegion:region animated:false];
        
        //to avoid the bug of AMAP
        CLLocationCoordinate2D coord = region.center;
        [_mapView setCenterCoordinate:coord];
        
        //make the lines in the map
        //[_mapView addOverlay:[self polyLine]];
        
        NSArray *colorSegmentArray = [MathController colorSegmentsForLocations:self.run.locations.array];
        [_mapView addOverlays:colorSegmentArray];

        
    } else {
        //no location were found
        _mapView.hidden = YES;

        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Sorry, this run has no locations saved."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
        [alertView show];
    }

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame), CGRectGetWidth(self.view.bounds), 360)];
    _mapView.delegate = self;
    
    //_mapView.showsUserLocation = YES;
    _mapView.showsCompass = NO;
    
    [_mapView setZoomLevel:16.1 animated:YES];
    
    [self.view addSubview:_mapView];
    
    [self configureView];
    
    _geocoder = [[CLGeocoder alloc] init];

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
