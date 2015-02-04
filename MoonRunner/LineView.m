//
//  LineView.m
//  MoonRunner
//
//  Created by Youwen Yi on 1/28/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "LineView.h"

@implementation LineView{

    double _viewOffset;
}

@synthesize startPoint;
@synthesize endPoint;
@synthesize positionData;
@synthesize rectHeight;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)drawRect:(CGRect)rect{

    //NSLog(@"maxY:%f",CGRectGetMaxY(self.frame));
    
    double maxX = CGRectGetMaxX(self.frame);
    double minX = CGRectGetMinX(self.frame);
    
    double maxY = rectHeight;
    double minY = CGRectGetMinY(self.frame);
    
    _viewOffset = minY;
    
    //UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 3.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    
    if (self.positionData.count > 1) {
        startPoint = [self.positionData[0] CGPointValue];
        CGContextMoveToPoint(context, startPoint.x, startPoint.y - _viewOffset);
        
        for (NSInteger i = 1; i < self.positionData.count; i++) {
            CGPoint point = [self.positionData[i] CGPointValue];
            
            point.x = fmin(fmax(point.x, minX), maxX);
            point.y = fmin(fmax(point.y, minY), maxY);
            point.y -= _viewOffset;
            
            CGContextAddLineToPoint(context, point.x, point.y);
            
        }
        
        CGContextStrokePath(context);
        
    }

}

-(void)layoutSubviews{

    self.backgroundColor = [UIColor clearColor];

}

@end
