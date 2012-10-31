//
//  RWBasicAnnotation.m
//
//  Created by Anton Schukin on 10/26/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWBasicAnnotation.h"

@implementation RWBasicAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    
    if (self) {
        _coordinate = coordinate;
    }
    
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = _coordinate;
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
}

- (void)setSubtitle:(NSString *)subtitle
{
    _subtitle = [subtitle copy];
}

@end
