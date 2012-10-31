//
//  RWBasicClusterAnnotation.m
//  RWMapExample
//
//  Created by Anton Schukin on 10/26/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWBasicClusterAnnotation.h"

@implementation RWBasicClusterAnnotation

- (id)init
{
    self = [super init];
    
    if (self) {
        _containedAnnotations = [NSArray array];
    }
    
    return self;
}

- (id)initWithContainedAnnotations:(NSArray *)containedAnnotations
{
    self = [super init];
    
    if (self) {
        self.containedAnnotations = containedAnnotations;
    }
    
    return self;
}

- (void)setContainedAnnotations:(NSArray *)containedAnnotations
{
    if (containedAnnotations == _containedAnnotations) return;
    
    _containedAnnotations = containedAnnotations;
    
    double lat = 0.0;
    double lon = 0.0;
    
    for (id<MKAnnotation> ann in self.containedAnnotations) {
        lat += ann.coordinate.latitude;
        lon += ann.coordinate.longitude;
    }
    
    _coordinate = CLLocationCoordinate2DMake(lat/[self.containedAnnotations count], lon/[self.containedAnnotations count]);
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    if (_containedAnnotations) return;
    
    _coordinate = newCoordinate;
}

- (CLLocationCoordinate2D) coordinate
{
    return _coordinate;
}

- (NSString *)title
{
    return [NSString stringWithFormat:@"%d", _containedAnnotations.count];
}

@end
