//
//  HomeViewController.m
//  MoonRunner
//
//  Created by Youwen Yi on 1/19/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "HomeViewController.h"
#import "NewRunViewController.h"
#import "PastRunsViewController.h"
#import <MAMapKit/MAMapKit.h>

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Runner";
    
    [MAMapServices sharedServices].apiKey = @"4fe484996ceb60d3e2b7ee03f7280d68";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    UIViewController *nextController = [segue destinationViewController];
    if ([nextController isKindOfClass:[NewRunViewController class]]) {
        ((NewRunViewController *) nextController).managedObjectContext = self.managedObjectContext;
        
    }else if ([nextController isKindOfClass:[PastRunsViewController class]]){
        ((PastRunsViewController *) nextController).managedObjectContext = self.managedObjectContext;
    
    }

}

//change the system style
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
