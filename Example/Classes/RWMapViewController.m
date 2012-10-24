//
//  RWMapViewController.m
//  RWMapExample
//
//  Created by Anton Schukin on 10/23/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWMapViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface RWMapViewController ()

@end

@implementation RWMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapView.delegate = self;
    
    _propertiesView.layer.cornerRadius = 7.0f;
    _propertiesView.layer.borderWidth = 1;
    _propertiesView.layer.borderColor = [UIColor blackColor].CGColor;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RWMapViewDelegate methods
- (void)mapViewWillChangeZoomScale:(MKMapView *)mapView
{
    
}

- (void)mapViewDidChangeZoomScale:(MKMapView *)mapView
{
    self.zoomValueLabel.text = [NSString stringWithFormat:@"%d", self.mapView.zoomScale];
}

@end
