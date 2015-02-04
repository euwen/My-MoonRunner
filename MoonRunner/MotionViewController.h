//
//  MotionViewController.h
//  MoonRunner
//
//  Created by Youwen Yi on 1/22/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MotionViewController : UIViewController

@property(nonatomic, weak)IBOutlet UILabel *accLabel;

@property(nonatomic, weak)IBOutlet UILabel *gyroLabel;

@property(nonatomic, weak)IBOutlet UILabel *magLabel;

@property(nonatomic, weak)IBOutlet UILabel *attLabel;

@property(nonatomic, weak)IBOutlet UILabel *stepLabel;

@property (strong, nonatomic) IBOutlet UISwitch *sensorSwitch;


@end
