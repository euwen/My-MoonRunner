//
//  LineView.h
//  MoonRunner
//
//  Created by Youwen Yi on 1/28/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LineView : UIView

@property(nonatomic) CGPoint startPoint;

@property(nonatomic) CGPoint endPoint;

@property(nonatomic, strong)NSMutableArray *positionData;

@property(nonatomic) double rectHeight;

@end
