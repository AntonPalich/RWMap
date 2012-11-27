//
//  RWAnnotationView.h
//
//  Created by Anton Schukin on 10/16/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RWAnnotationView <NSObject>

@optional

- (void)mapViewDidSelectAnnotationView:(MKMapView *)mapView;
- (void)mapViewDidDeselectAnnotationView:(MKMapView *)mapView;
- (BOOL)shouldShowCalloutView:(MKMapView *)mapView;

@end
