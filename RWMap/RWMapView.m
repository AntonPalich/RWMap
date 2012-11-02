//
//  RWMapView.m
//
//  Created by Anton Schukin on 10/15/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWMapView.h"

#import "RWClusterOperation.h"

@interface RWMapView() {
    
    NSInteger _currentZoomLevel;
    
    id<RWMapViewDelegate> _delegate;
    
    NSMutableArray *_cachedAnnotations;
    
    NSOperationQueue *_clusterOperationQueue;
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
    
    self.clusterRadius = 100;
    
    _cachedAnnotations = [NSMutableArray new];
    _clusterOperationQueue = [[NSOperationQueue alloc] init];
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
        
        [self addClusterAnnotations:annotations];
        
    } else {
    
        [super addAnnotations:annotations];
        
    }
}

- (void)addClusterAnnotations:(NSArray *)annotations
{
    [_cachedAnnotations addObjectsFromArray:annotations];
    [self calculateClusterAnnotations];
}

- (void)calculateClusterAnnotations
{
    MKMapView *tempMapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    [tempMapView addAnnotations:_cachedAnnotations];
    
    NSSet *visibleAnnotations = [tempMapView annotationsInMapRect:self.visibleMapRect];
    
    NSMutableSet *otherAnnotations = [NSMutableSet setWithArray:_cachedAnnotations];
    [otherAnnotations minusSet:visibleAnnotations];
    
    RWClusterOperation *visibleClusterOperation = [[RWClusterOperation alloc] initWithMapView:self
                                                                                  annotations:[visibleAnnotations allObjects]
                                                                                   completion:^(NSArray *clusterAnnotations)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [super removeAnnotations:[super annotations]];
            [super addAnnotations:clusterAnnotations];                
        });
    }];
    
    RWClusterOperation *otherClusterOperation = [[RWClusterOperation alloc] initWithMapView:self
                                                                                annotations:[otherAnnotations allObjects]
                                                                                 completion:^(NSArray *clusterAnnotations)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [super addAnnotations:clusterAnnotations];
        });
    }];
    
    [otherClusterOperation addDependency:visibleClusterOperation];
    
    [_clusterOperationQueue cancelAllOperations];
    [_clusterOperationQueue addOperation:visibleClusterOperation];
    [_clusterOperationQueue addOperation:otherClusterOperation];
    
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation
{
    [super removeAnnotation:annotation];
    
    [self removeAnnotationFromCache:annotation];
}

- (void)removeAnnotations:(NSArray *)annotations
{
    [super removeAnnotations:annotations];
    
    for (id<MKAnnotation> annotation in annotations) {
        
        [self removeAnnotationFromCache:annotation];
        
    }
}

- (void)removeAllAnnotations
{
    [_cachedAnnotations removeAllObjects];
    [self removeAnnotations:self.annotations];
}

- (void)removeAnnotationFromCache:(id<MKAnnotation>)annotation
{
    if ([annotation conformsToProtocol:@protocol(RWClusterAnnotation)]) {
        
        NSArray *containedAnnotations = ((id<RWClusterAnnotation>)annotation).containedAnnotations;
        
        for (id<MKAnnotation> containedAnnotation in containedAnnotations) {
            
            if ([_cachedAnnotations containsObject:containedAnnotation]) {
                [_cachedAnnotations removeObject:containedAnnotation];
            }
            
        }
        
    } else {
        
        if ([_cachedAnnotations containsObject:annotation]) {
            [_cachedAnnotations removeObject:annotation];
        }
        
    }
}
#pragma mark - Setting map center
- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSInteger)zoomLevel
{
    [self setCenterCoordinate:centerCoordinate zoomLevel:zoomLevel animated:NO];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate zoomLevel:(NSInteger)zoomLevel animated:(BOOL)animated
{

    // FIX: difference behavior for difference orientations and interface idioms
    int interfaceOrientationFactor;
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
        interfaceOrientationFactor = 0;
    } else {
        interfaceOrientationFactor = 1;
    }
    
    float newZoomLevel = MIN(MAX(0, zoomLevel), 18) + interfaceOrientationFactor;
    double zoomFactor = pow(2, newZoomLevel);
    
    // Set size
    MKMapRect newVisibleRect;
    
    if (self.visibleMapRect.size.width > self.visibleMapRect.size.height) {
        newVisibleRect = MKMapRectMake(0, 0, MKMapRectWorld.size.width / zoomFactor, 0.1);
    } else {
        newVisibleRect = MKMapRectMake(0, 0, 0.1, MKMapRectWorld.size.height / zoomFactor);
    }
    
    newVisibleRect = [self mapRectThatFits:newVisibleRect];
    
    // Set origin
    MKMapPoint newCenterPoint = MKMapPointForCoordinate(coordinate);
    newVisibleRect = MKMapRectMake(newCenterPoint.x - newVisibleRect.size.width / 2,
                                   newCenterPoint.y - newVisibleRect.size.height / 2,
                                   // FIX: - 1 fixing iOS 6 MapKit bug
                                   newVisibleRect.size.width - 1,
                                   newVisibleRect.size.height);
    
    [self setVisibleMapRect:newVisibleRect animated:animated];

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

        if (self.useClusters) {
            [self calculateClusterAnnotations];
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
@end