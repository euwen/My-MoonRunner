//
//  DetailViewController.h
//  MoonRunner
//
//  Created by Youwen Yi on 1/16/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

