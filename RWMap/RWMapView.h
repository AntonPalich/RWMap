//
//  RWMapView.h
//  NorthWestEstate
//
//  Created by Anton Schukin on 10/15/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "RWClusterAnnotation.h"
#import "RWCalloutAnnotation.h"

@protocol RWMapViewDelegate <MKMapViewDelegate>

@optional

- (void)mapViewWillChangeZoomScale:(MKMapView *)mapView;
- (void)mapViewDidChangeZoomScale:(MKMapView *)mapView;

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForClusterAnnotation:(id<RWClusterAnnotation>)annotation;
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForCalloutAnnotation:(id<RWCalloutAnnotation>)annotation;

- (id<RWClusterAnnotation>)mapViewAnnotationForClustering:(MKMapView *)mapView;

@end

@interface RWMapView : MKMapView <MKMapViewDelegate>

@property (nonatomic, assign) id<RWMapViewDelegate> delegate;

@property (nonatomic, readonly) NSInteger zoomScale;
- (NSInteger)zoomScaleForMapRect:(MKMapRect)mapRect;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomScale:(NSInteger)zoomScale;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate zoomScale:(NSInteger)zoomScale animated:(BOOL)animated;

@property (nonatomic, assign) BOOL useCustomCalloutView;

@property (nonatomic, assign) BOOL useClusters;
@property (nonatomic, assign) float distanceForClustering;

@end

