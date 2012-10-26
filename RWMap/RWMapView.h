//
//  RWMapView.h
//
//  Created by Anton Schukin on 10/15/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "RWClusterAnnotation.h"
#import "RWCalloutAnnotation.h"

@protocol RWMapViewDelegate <MKMapViewDelegate>

@optional

- (void)mapViewWillChangeZoomLevel:(MKMapView *)mapView;
- (void)mapViewDidChangeZoomLevel:(MKMapView *)mapView;

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForClusterAnnotation:(id<RWClusterAnnotation>)annotation;
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForCalloutAnnotation:(id<RWCalloutAnnotation>)annotation;

- (id<RWClusterAnnotation>)mapViewAnnotationForClustering:(MKMapView *)mapView;

@end

@interface RWMapView : MKMapView <MKMapViewDelegate>

@property (nonatomic, assign) id<RWMapViewDelegate> delegate;

@property (nonatomic, readonly) NSInteger zoomLevel;
- (NSInteger)zoomLevelForMapRect:(MKMapRect)mapRect;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSInteger)zoomLevel;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate zoomLevel:(NSInteger)zoomLevel animated:(BOOL)animated;

@property (nonatomic, assign) BOOL useCustomCalloutView;

@property (nonatomic, assign) BOOL useClusters;
@property (nonatomic, assign) float distanceForClustering;

@end

