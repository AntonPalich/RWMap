//
//  RWMapView.m
//
//  Created by Anton Schukin on 10/15/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWMapView.h"

@interface RWMapView() {
    
    NSInteger _currentZoomLevel;
    
    id<RWMapViewDelegate> _delegate;
    
}

@end

@implementation RWMapView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupMapView];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setupMapView];
    }
    
    return self;
}

- (void)setupMapView
{
    [super setDelegate:self];
    
    _currentZoomLevel = 0;
    
    self.useClusters = NO;
    self.useCustomCalloutView = NO;
    
    self.distanceForClustering = 100;
}
#pragma mark - Properties
- (NSInteger)zoomLevel
{
    return _currentZoomLevel;
}

- (id<RWMapViewDelegate>)delegate
{
    return _delegate;
}

- (void)setDelegate:(id<RWMapViewDelegate>)delegate
{
    _delegate = delegate;
}

#pragma mark - Class methods
- (NSInteger)zoomLevelForMapRect:(MKMapRect)mapRect
{
    CGFloat maxSize = MAX(mapRect.size.width, mapRect.size.height);
    
    CGFloat worldSize;
    
    if (maxSize == mapRect.size.width) {
        worldSize = MKMapRectWorld.size.width;
    } else {
        worldSize = MKMapRectWorld.size.height;
    }
    
    double zoomLevel = worldSize / maxSize;
    zoomLevel = floor(log2(zoomLevel));
    
    return zoomLevel;
}

- (void)addAnnotations:(NSArray *)annotations {
    
    if (self.useClusters) {
        
        [self clustersForAnnotations:annotations distance:self.distanceForClustering completion:^(NSArray *data) {
            
            [super removeAnnotations:[super annotations]];
            [super addAnnotations:data];
            
        }];
        
        return;
    }
    
    [super addAnnotations:annotations];
}

#pragma mark - Setting map center
- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSInteger)zoomLevel
{
    [self setCenterCoordinate:centerCoordinate zoomLevel:zoomLevel animated:NO];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate zoomLevel:(NSInteger)zoomLevel animated:(BOOL)animated
{
    NSInteger minZoomLevel;

    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        minZoomLevel = 1;
    } else {
        minZoomLevel = 0;
    }
    
    float newZoomLevel = MIN(MAX(minZoomLevel, zoomLevel), 18);
    double zoomFactor = pow(2, newZoomLevel);
    
    // Set size
    MKMapRect newVisibleRect;
    
    if (self.visibleMapRect.size.width > self.visibleMapRect.size.height) {
        newVisibleRect = MKMapRectMake(0, 0, MKMapRectWorld.size.width / zoomFactor, 0);
    } else {
        newVisibleRect = MKMapRectMake(0, 0, 0, MKMapRectWorld.size.height / zoomFactor);
    }
    
    newVisibleRect = [self mapRectThatFits:newVisibleRect];
    
    // Set origin
    MKMapPoint newCenterPoint = MKMapPointForCoordinate(coordinate);
    newVisibleRect = MKMapRectMake(newCenterPoint.x - newVisibleRect.size.width / 2,
                                   newCenterPoint.y - newVisibleRect.size.height / 2,
                                   // FIX: - 1 fixing iOS 6 MapKit bug
                                   newVisibleRect.size.width - 1,
                                   newVisibleRect.size.height);
    
    NSLog(@"visible before: x: %f y: %f width: %f height: %f", self.visibleMapRect.origin.x, self.visibleMapRect.origin.y, self.visibleMapRect.size.width, self.visibleMapRect.size.height);
    NSLog(@"new:     x: %f y: %f width: %f height: %f", newVisibleRect.origin.x, newVisibleRect.origin.y, newVisibleRect.size.width, newVisibleRect.size.height);
    NSLog(@"world:   x: %f y: %f width: %f height: %f", MKMapRectWorld.origin.x, MKMapRectWorld.origin.y, MKMapRectWorld.size.width, MKMapRectWorld.size.height);
    
    [self setVisibleMapRect:newVisibleRect animated:animated];
    
    NSLog(@"visible after : x: %f y: %f width: %f height: %f", self.visibleMapRect.origin.x, self.visibleMapRect.origin.y, self.visibleMapRect.size.width, self.visibleMapRect.size.height);
    NSLog(@" ");

}

#pragma mark - Responding to Map Position Changes
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if ([_delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)]) {
        [_delegate mapView:mapView regionWillChangeAnimated:animated];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    float zoomLevel = [self zoomLevelForMapRect:[mapView visibleMapRect]];
    
    if (_currentZoomLevel != zoomLevel) {
        
        if ([_delegate respondsToSelector:@selector(mapViewWillChangeZoomLevel:)]) {
            [_delegate mapViewWillChangeZoomLevel:mapView];
        }
        
        _currentZoomLevel = zoomLevel;
        
        if ([_delegate respondsToSelector:@selector(mapViewDidChangeZoomLevel:)]) {
            [_delegate mapViewDidChangeZoomLevel:mapView];
        }
    }
    
    if ([_delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        [_delegate mapView:mapView regionDidChangeAnimated:animated];
    }
}

#pragma mark - Loading the Map Data
- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
    if ([_delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)]) {
        [_delegate mapViewWillStartLoadingMap:mapView];
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    if ([_delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)]) {
        [_delegate mapViewDidFinishLoadingMap:mapView];
    }
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError:)]) {
        [_delegate mapViewDidFailLoadingMap:mapView withError:error];
    }
}

#pragma mark - Tracking the User Location
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    if ([_delegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)]) {
        [_delegate mapViewWillStartLocatingUser:mapView];
    }
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    if ([_delegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)]) {
        [_delegate mapViewDidStopLocatingUser:mapView];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if ([_delegate respondsToSelector:@selector(mapView:didUpdateUserLocation::)]) {
        [_delegate mapView:mapView didUpdateUserLocation:userLocation];
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)]) {
        [_delegate mapView:mapView didFailToLocateUserWithError:error];
    }
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if ([_delegate respondsToSelector:@selector(mapView:didChangeUserTrackingMode:animated:)]) {
        [_delegate mapView:mapView didChangeUserTrackingMode:mode animated:animated];
    }
}

#pragma mark - Managing Annotation Views
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation conformsToProtocol:@protocol(RWClusterAnnotation)]) {
        if ([_delegate respondsToSelector:@selector(mapView:viewForClusterAnnotation:)]){
            return [_delegate mapView:mapView viewForClusterAnnotation:(id<RWClusterAnnotation>)annotation];
        }
    }
    
    if ([annotation conformsToProtocol:@protocol(RWCalloutAnnotation)]) {
        if ([_delegate respondsToSelector:@selector(mapView:viewForClusterAnnotation:)]){
            return [_delegate mapView:mapView viewForCalloutAnnotation:(id<RWCalloutAnnotation>)annotation];
        }
    }
    
    if ([_delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        return [_delegate mapView:mapView viewForAnnotation:annotation];
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    if ([_delegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)]) {
        [_delegate mapView:mapView didAddAnnotationViews:views];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([_delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)]) {
        [_delegate mapView:mapView annotationView:view calloutAccessoryControlTapped:control];
    }
}

#pragma mark - Dragging an Annotation View
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if ([_delegate respondsToSelector:@selector(mapView:annotationView:didChangeDragState:fromOldState:)]) {
        [_delegate mapView:mapView annotationView:view didChangeDragState:newState fromOldState:oldState];
    }
}

#pragma mark - Selecting Annotation Views
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([_delegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
        [_delegate mapView:mapView didSelectAnnotationView:view];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([_delegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)]) {
        [_delegate mapView:mapView didDeselectAnnotationView:view];
    }
}

#pragma mark - Managing Overlay Views
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if ([_delegate respondsToSelector:@selector(mapView:viewForOverlay:)]) {
        return [_delegate mapView:mapView viewForOverlay:overlay];
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews
{
    if ([_delegate respondsToSelector:@selector(mapView:didAddOverlayViews:)]) {
        [_delegate mapView:mapView didAddOverlayViews:overlayViews];
    }
}

#pragma mark - Clustering
- (float) approxDistanceCoord1:(CLLocationCoordinate2D)coord1 coord2:(CLLocationCoordinate2D)coord2 {

    CGPoint pt1;
    CGFloat zoomFactor =  self.visibleMapRect.size.width / self.bounds.size.width;
    MKMapPoint mapPoint1 = MKMapPointForCoordinate(coord1);
    pt1.x = mapPoint1.x/zoomFactor;
    pt1.y = mapPoint1.y/zoomFactor;
    
    CGPoint pt2;
    MKMapPoint mapPoint2 = MKMapPointForCoordinate(coord2);
    pt2.x = mapPoint2.x/zoomFactor;
    pt2.y = mapPoint2.y/zoomFactor;
    
    
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
    for (id<MKAnnotation> k in neighbourhood)
    {
        if (k == ann) {
            continue;
        }
        
        if ([self shouldAvoidClustersAnnotation:k]) {
            continue;
        }
        
        if ([self approxDistanceCoord1:ann.coordinate coord2:k.coordinate] < distance)
        {
            [result addObject:k];
        }
    }
    
    if ([result count] == 0) {
        return nil;
    }
    return result;
}


- (void) clustersForAnnotations:(NSArray*)annotations distance:(float)distance completion:(void (^)(NSArray *data))block {
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [queue addOperationWithBlock:^{
        
        NSMutableArray *processed = [NSMutableArray array];
        NSMutableArray *restOfAnnotations = [NSMutableArray arrayWithArray:annotations];
        NSMutableArray *finalAnns = [NSMutableArray array];
        
        for (id<MKAnnotation> ann in [NSArray arrayWithArray:annotations]) {
            
            if ([processed containsObject:ann]) {
                continue;
            }
            
            [processed addObject:ann];
            
            if ([self shouldAvoidClustersAnnotation:ann]) {
                [finalAnns addObject:ann];
                continue;
            }
            
            NSArray *neighbours = [self findNeighboursForAnnotation:ann inNeighbourdhood:restOfAnnotations withDistance:distance];
            
            if (!neighbours) {
                
                [finalAnns addObject:ann];
                
            } else {
                
                [processed addObjectsFromArray:neighbours];

                id<RWClusterAnnotation> cluster;
                
                if ([_delegate respondsToSelector:@selector(mapViewAnnotationForClustering:)]) {
                    
                    NSMutableArray *containedAnnotations = [NSMutableArray arrayWithArray:neighbours];
                    [containedAnnotations addObject:ann];
                    
                    cluster = [_delegate mapViewAnnotationForClustering:self];
                    cluster.containedAnnotations = [NSArray arrayWithArray:containedAnnotations];

                }
                
                [finalAnns addObject:cluster];
                
            }
            
            [restOfAnnotations removeObjectsInArray:processed];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            block(finalAnns);
        }];
        
    }];
}
@end