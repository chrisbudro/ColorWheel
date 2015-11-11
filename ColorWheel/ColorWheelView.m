//
//  ColorWheelView.m
//  ColorWheel
//
//  Created by Chris Budro on 11/7/15.
//  Copyright © 2015 Chris Budro. All rights reserved.
//

#import "ColorWheelView.h"
#import "Colors.h"

@interface ColorWheelView ()

@property (strong, nonatomic) NSArray *colors;

@property (nonatomic) CGPoint circleCenter;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat pieHeight;

@end

@implementation ColorWheelView

-(instancetype)initWithColors:(NSArray *)colors {
  self = [super init];
  if (self) {
    self.colors = colors;
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  self.circleCenter = CGPointMake(rect.size.width/2, rect.size.height/2);
  self.radius = MAX(rect.size.width, rect.size.height) / 2;
  self.pieHeight = self.radius - self.radius/2;
  
  CGFloat pieAngle = 2*M_PI / (CGFloat)self.colors.count;
  
  for (int i = 0; i < self.colors.count; i++) {
    CGFloat centerAngle = pieAngle * (CGFloat)i;
    CGFloat startAngle = centerAngle - pieAngle/2;
    CGFloat endAngle = centerAngle + pieAngle/2;
    
    [self drawPieWithColor:self.colors[i] withStartAngle:startAngle endAngle:endAngle];
  }
}

#pragma mark - Helper Methods

-(void)drawPieWithColor:(UIColor *)color withStartAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
  UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:self.circleCenter radius:self.pieHeight startAngle:startAngle endAngle:endAngle clockwise:true];
  
  [color setStroke];
  path.lineWidth = self.radius;
  [path stroke];
}

@end