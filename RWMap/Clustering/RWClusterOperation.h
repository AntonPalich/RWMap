//
//  RWClusterOperation.h
//  RWMapExample
//
//  Created by Anton Schukin on 10/30/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RWMapView.h"

@interface RWClusterOperation : NSOperation

- (id)initWithMapView:(RWMapView *)mapView annotations:(NSArray *)annotations completion:(void (^)(NSArray *clusterAnnotations))completion;

@end
