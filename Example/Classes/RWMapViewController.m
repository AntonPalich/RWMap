//
//  RWMapViewController.m
//  RWMapExample
//
//  Created by Anton Schukin on 10/23/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWMapViewController.h"

#import "RWBasicAnnotation.h"
#import "RWBasicClusterAnnotation.h"

@interface RWMapViewController () {
    NSTimer *_updateUITimer;
    NSArray *_annotations;
}

@end

@implementation RWMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapView.delegate = self;
    _mapView.useClusters = YES;
    _mapView.distanceForClustering = 100;
    
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
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

#pragma mark - MKMapViewDelegate methods
- (id<RWClusterAnnotation>)mapView:(MKMapView *)mapView clusterAnnotationForAnnotations:(NSArray *)annotations
{
    return [[RWBasicClusterAnnotation alloc] initWithContainedAnnotations:annotations];
}

#pragma mark - RWMapViewDelegate methods
- (void)mapViewDidChangeZoomLevel:(MKMapView *)mapView
{
    self.zoomValueLabel.text = [NSString stringWithFormat:@"%d", self.mapView.zoomLevel];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:_annotations];
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

- (void)generateAnnotations:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSMutableArray *annotations = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < 1000; i++) {
            
            double latitude = - 80 + (double)(arc4random() % 160000000) / (double)1000000;
            double longitude = - 170 + (double)(arc4random() % 340000000) / (double)1000000;
            
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            
            RWBasicAnnotation *annotation = [[RWBasicAnnotation alloc] initWithCoordinate:coordinate];
            [annotations addObject:annotation];
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _annotations = [NSArray arrayWithArray:annotations];
            [self.mapView addAnnotations:_annotations];
            
        });
        
    });
    
}

- (void)removeAnnotations:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
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
