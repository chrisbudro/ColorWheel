//
//  ViewController.m
//  ColorWheel
//
//  Created by Chris Budro on 11/7/15.
//  Copyright © 2015 Chris Budro. All rights reserved.
//

#import "MainViewController.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import "ColorWheelView.h"
#import "Constants.h"
#import "ColorsManager.h"
#import "SpinGestureRecognizer.h"
#import "ColorWheelDelegate.h"

CGFloat const kColorWheelToSuperViewMultiplier = 0.80;

@interface MainViewController () <WCSessionDelegate>


@property (strong, nonatomic) ColorWheelView *colorWheelView;
@property (strong, nonatomic) ColorsManager *colorsManager;
@property (strong, nonatomic) WCSession *session;
@property (strong, nonatomic) SpinGestureRecognizer *spinGesture;
@property (strong, nonatomic) id <ColorWheelDelegate> colorWheelDelegate;

@property (strong, nonatomic) NSLayoutConstraint *portraitScaleConstraint;
@property (strong, nonatomic) NSLayoutConstraint *landscapeScaleConstraint;

@end

@implementation MainViewController

#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupColorWheel];
  [self setupWatchConnectivitySession];
  
  [[NSNotificationCenter defaultCenter] addObserver:self.colorsManager selector:@selector(save) name:UIApplicationWillResignActiveNotification object:nil];
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self.colorsManager];
}

#pragma mark - Color Wheel Setup

-(void)setupColorWheel {
  self.colorsManager = [[ColorsManager alloc] init];
  self.colorWheelDelegate = [[ColorWheelDelegate alloc] initWithColors:[self.colorsManager colorList]];
  self.colorWheelView = [[ColorWheelView alloc] initWithDelegate:self.colorWheelDelegate];
  [self.colorWheelView.delegate colorWheel:self.colorWheelView spinToColorAtIndex:self.colorsManager.currentIndex];
  self.spinGesture = [[SpinGestureRecognizer alloc] initWithTarget:self action:@selector(handleSpin:)];
  [self.colorWheelView addGestureRecognizer:self.spinGesture];
  
  [self.view addSubview:self.colorWheelView];
  [self setupColorWheelConstraints];
}

-(void)setupColorWheelConstraints {
  self.view.translatesAutoresizingMaskIntoConstraints = false;
  self.colorWheelView.translatesAutoresizingMaskIntoConstraints = false;
  
  self.landscapeScaleConstraint = [NSLayoutConstraint constraintWithItem:self.colorWheelView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:kColorWheelToSuperViewMultiplier constant:0];
  self.portraitScaleConstraint = [NSLayoutConstraint constraintWithItem:self.colorWheelView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:kColorWheelToSuperViewMultiplier constant:0];
  NSLayoutConstraint *aspectRatio = [NSLayoutConstraint constraintWithItem:self.colorWheelView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.colorWheelView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
  NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.colorWheelView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
  NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.colorWheelView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
  
  aspectRatio.active = true;
  centerX.active = true;
  centerY.active = true;
  [self setOrientationConstraintWithSize:self.view.bounds.size];
  }

-(void)setOrientationConstraintWithSize:(CGSize)size {
  BOOL isLandscape = size.width > size.height;
  if (isLandscape) {
    self.portraitScaleConstraint.active = false;
    self.landscapeScaleConstraint.active = true;
  } else {
    self.landscapeScaleConstraint.active = false;
    self.portraitScaleConstraint.active = true;
  }
}

#pragma mark - Spin Handler

-(void)handleSpin:(SpinGestureRecognizer *)spinGesture {
  
  if (spinGesture.state == UIGestureRecognizerStateEnded) {
    CGFloat currentAngle = [spinGesture currentRotationAngle];
    NSInteger newIndex = [self.colorWheelView.delegate colorWheel:self.colorWheelView adjustedIndexForAngle:currentAngle];
    [self setNewIndex:newIndex];
  }
}

-(void)setNewIndex:(NSInteger)index {
  [self.colorsManager updateCurrentIndex:index];
  [self sendColorIndexToWatch:index];
  [self.colorWheelView.delegate colorWheel:self.colorWheelView spinToColorAtIndex:index];
}

#pragma mark - Watch Session Delegate

-(void)setupWatchConnectivitySession {
  self.session = [WCSession defaultSession];
  self.session.delegate = self;
  [self.session activateSession];
  
  if (self.session.reachable) {
    [self sendColorIndexToWatch:self.colorsManager.currentIndex];
  }
}

-(void)sendColorIndexToWatch:(NSInteger)index {
  NSNumber *updatedIndex = [NSNumber numberWithInteger:index];
  NSDictionary *message = @{kUpdatedColorIndexKey: updatedIndex};
  [self.session sendMessage:message replyHandler:nil errorHandler:nil];
}

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
  NSNumber *updatedIndex = message[kUpdatedColorIndexKey];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.colorWheelView.delegate colorWheel:self.colorWheelView spinToColorAtIndex:updatedIndex.integerValue];
    [self.colorsManager updateCurrentIndex:updatedIndex.integerValue];
  });
}

-(void)sessionReachabilityDidChange:(WCSession *)session {
  if (session.reachable) {
    [self sendColorIndexToWatch:self.colorsManager.currentIndex];
  }
}

#pragma mark - Orientation Handling
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [self setOrientationConstraintWithSize:size];
  [self.view layoutIfNeeded];
}

@end
