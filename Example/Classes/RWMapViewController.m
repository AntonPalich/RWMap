//
//  RWMapViewController.m
//  RWMapExample
//
//  Created by Anton Schukin on 10/23/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWMapViewController.h"

@interface RWMapViewController () {
    NSTimer *_updateUITimer;
}

@end

@implementation RWMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapView.delegate = self;
    
    _propertiesView.layer.cornerRadius = 7.0f;
    _propertiesView.layer.borderWidth = 1;
    _propertiesView.layer.borderColor = [UIColor blackColor].CGColor;
    
    _updateUITimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_updateUITimer forMode:NSRunLoopCommonModes];
    
}

- (void)dealloc
{
    [_updateUITimer invalidate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

#pragma mark - MKMapViewDelegate methods
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{    

}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    
}

#pragma mark - RWMapViewDelegate methods
- (void)mapViewDidChangeZoomScale:(MKMapView *)mapView
{
    self.zoomValueLabel.text = [NSString stringWithFormat:@"%d", self.mapView.zoomLevel];
}

#pragma mark - Actions
- (void)zoomIn:(id)sender
{
    [self.mapView setCenterCoordinate:self.mapView.centerCoordinate zoomLevel:self.mapView.zoomLevel + 1 animated:YES];
}

- (void)zoomOut:(id)sender
{
    [self.mapView setCenterCoordinate:self.mapView.centerCoordinate zoomLevel:self.mapView.zoomLevel - 1 animated:YES];

}

#pragma mark - Helpers
- (void)updateUI
{
    self.centerLatitudeLabel.text = [NSString stringWithFormat:@"%f", self.mapView.region.center.latitude];
    self.centerLongitudeLabel.text = [NSString stringWithFormat:@"%f", self.mapView.region.center.longitude];
    
    self.spanLatitudeLabel.text = [NSString stringWithFormat:@"%f", self.mapView.region.span.latitudeDelta];
    self.spanLongitudeLabel.text = [NSString stringWithFormat:@"%f", self.mapView.region.span.longitudeDelta];
}

@end
