//
//  RWCalloutAnnotation.h
//
//  Created by Anton Schukin on 10/16/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RWCalloutAnnotation <NSObject>

@property (nonatomic, weak) MKAnnotationView *parentAnnotationView;
@property (nonatomic, weak) MKMapView *mapView;

@end
