//
//  RWClusterOperation.m
//  RWMapExample
//
//  Created by Anton Schukin on 10/30/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWClusterOperation.h"

typedef void (^CompletionBlock)(NSArray *clusterAnnotations);

@interface RWClusterOperation () {
    CompletionBlock _completionBlock;
    NSArray *_annotations;
    RWMapView *_mapView;
}
@end

@implementation RWClusterOperation

- (id)initWithMapView:(RWMapView *)mapView annotations:(NSArray *)annotations completion:(void (^)(NSArray *clusterAnnotations))completion;
{
    self = [super init];
    
    if (self) {
        _completionBlock = completion;
        _annotations = annotations;
        _mapView = mapView;
    }
    
    return self;
}

- (void)dealloc
{
    _completionBlock = nil;
    _annotations = nil;
    _mapView = nil;
}

- (void)main
{    
    NSMutableArray *processed = [NSMutableArray array];
    NSMutableArray *restOfAnnotations = [NSMutableArray arrayWithArray:_annotations];
    NSMutableArray *finalAnns = [NSMutableArray array];
    
    NSDate *date = [NSDate date];
    
    int forCounter = 0;
    int elseCounter = 0;
    
    for (id<MKAnnotation> ann in _annotations) {
        
        if (self.isCancelled) {
            _completionBlock = nil;
            _annotations = nil;
            _mapView = nil;
            return;
        }
        
        forCounter++;
        
        if ([processed containsObject:ann]) {
            continue;
        }
        
        [processed addObject:ann];
        
        if ([self shouldAvoidClustersAnnotation:ann]) {
            [finalAnns addObject:ann];
            continue;
        }
        
        NSArray *neighbours = [self findNeighboursForAnnotation:ann inNeighbourdhood:restOfAnnotations withDistance:_mapView.clusterRadius];
        
        if (!neighbours) {
            [finalAnns addObject:ann];
            
        } else {
            
            elseCounter++;
            
            [processed addObjectsFromArray:neighbours];
            
            NSAssert([_mapView.delegate respondsToSelector:@selector(mapView:clusterAnnotationForAnnotations:)], @"Delegate should return view for clustering");
            
            NSMutableArray *containedAnnotations = [NSMutableArray arrayWithArray:neighbours];
            [containedAnnotations addObject:ann];
            
            id<RWClusterAnnotation> cluster = [_mapView.delegate mapView:_mapView clusterAnnotationForAnnotations:containedAnnotations];
            
            [finalAnns addObject:cluster];
            
        }
        
        [restOfAnnotations removeObjectsInArray:processed];
        
    }
    
    NSTimeInterval sinceDate = [date timeIntervalSinceNow] * - 1000.0f;
    NSLog(@"Cluster annotations calculated in %f with %d cycles, %d cluster creations", sinceDate, forCounter, elseCounter);
    
    _completionBlock(finalAnns);
    
}

#pragma mark - Clustering
- (float) approxDistanceCoord1:(CLLocationCoordinate2D)coord1 coord2:(CLLocationCoordinate2D)coord2 {
    
    // TODO кэшировать посчитанные расстояния
    
    CGPoint pt1 = [_mapView convertCoordinate:coord1 toPointToView:_mapView];
    CGPoint pt2 = [_mapView convertCoordinate:coord2 toPointToView:_mapView];
    
    int dx = (int)pt1.x - (int)pt2.x;
    int dy = (int)pt1.y - (int)pt2.y;
    
    dx = abs(dx);
    dy = abs(dy);
    
    if ( dx < dy ) {
        return dx + dy - (dx >> 1);
    } else {
        return dx + dy - (dy >> 1);
    }
}

- (BOOL)shouldAvoidClustersAnnotation:(id<MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return YES;
    }
    
    return NO;
}


- (NSArray*) findNeighboursForAnnotation:(id<MKAnnotation>)ann inNeighbourdhood:(NSArray*)neighbourhood withDistance:(float)distance
{
    NSMutableArray *result = [NSMutableArray array];
    
    for (id<MKAnnotation> k in neighbourhood) {
        
        if (k == ann) {
            continue;
        }
        
        if ([self shouldAvoidClustersAnnotation:k]) {
            continue;
        }
        
        float approxDistance = [self approxDistanceCoord1:ann.coordinate coord2:k.coordinate];
        
        if (approxDistance < distance)
        {
            [result addObject:k];
        }
    }
    
    if ([result count] == 0) {
        return nil;
    }
    return result;
}
@end