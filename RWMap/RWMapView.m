//
//  RWMapView.m
//
//  Created by Anton Schukin on 10/15/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import "RWMapView.h"
#import "RWClusterOperation.h"
#import "RWAnnotationView.h"


@interface RWMapView() {
    NSInteger _currentZoomLevel;
    id<RWMapViewDelegate> _delegate;
    id<RWCalloutAnnotation> _calloutAnnotation;
    NSMutableArray *_annotations;
    NSMutableArray *_annotationsClustered;
    NSMutableArray *_annotationsForClustering;
    NSOperationQueue *_clusterOperationQueue;
    MKMapView *_storageMapView;
}

@end

#define kDefaultZoomLevel 0
#define kDefaultRadius 100

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
    
    _currentZoomLevel = kDefaultZoomLevel;
    _clusterRadius = kDefaultRadius;
    
    _annotations = [NSMutableArray new];
    _annotationsClustered = [NSMutableArray new];
    _annotationsForClustering = [NSMutableArray new];
    _clusterOperationQueue = [NSOperationQueue new];
    _storageMapView = [[MKMapView alloc] initWithFrame:CGRectZero];
}

- (void)dealloc
{
    _annotations = nil;
    _annotationsClustered = nil;
    _annotationsForClustering = nil;
    _clusterOperationQueue = nil;
    _storageMapView = nil;
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
- (NSArray *)annotations
{
    NSMutableArray *annotations = [NSMutableArray new];
    [annotations addObjectsFromArray:_annotations];
    [annotations addObjectsFromArray:_annotationsForClustering];
    return [NSArray arrayWithArray:annotations];
}

- (void)addAnnotation:(id<MKAnnotation>)annotation cluster:(BOOL)cluster
{
    if (cluster) {
        
        [_annotationsForClustering addObject:annotation];
        
        [self resetClusterAnnotations];
        [self calculateClusterAnnotations];
        
    } else {
        
        [_annotations addObject:annotation];
        [super addAnnotation:annotation];
        
    }
}

- (void)addAnnotation:(id<MKAnnotation>)annotation
{
    [self addAnnotation:annotation cluster:NO];
}

- (void)addAnnotations:(NSArray *)annotations cluster:(BOOL)cluster
{
    if (cluster) {
        
        [_annotationsForClustering addObjectsFromArray:annotations];
        
        [self resetClusterAnnotations];
        [self calculateClusterAnnotations];
        
    } else {
        
        [_annotations addObjectsFromArray:annotations];
        [super addAnnotations:annotations];
        
    }
}

- (void)addAnnotations:(NSArray *)annotations
{
    [self addAnnotations:annotations cluster:NO];
}

- (void)addAnnotationsForClustering:(NSArray *)annotations
{
    [_annotationsForClustering addObjectsFromArray:annotations];
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation
{
    if ([self removeAnnotationFromCache:annotation]) {
        [self resetClusterAnnotations];
        [self calculateClusterAnnotations];
    }
}

- (BOOL)removeAnnotationFromCache:(id<MKAnnotation>)annotation
{
    BOOL needToReload = NO;
    
    if ([_annotationsClustered containsObject:annotation]){
        
        [_annotationsClustered removeObject:annotation];
        
        if ([annotation conformsToProtocol:@protocol(RWClusterAnnotation)]) {
            
            NSArray *containedAnnotations = ((id<RWClusterAnnotation>)annotation).containedAnnotations;
            
            for (id<MKAnnotation> containedAnnotation in containedAnnotations) {
                
                if ([_annotationsForClustering containsObject:containedAnnotation]) {
                    [_annotationsForClustering removeObject:containedAnnotation];
                }
                
            }
            
        } else {
            
            [_annotationsForClustering removeObject:annotation];
            
        }
        
        needToReload = YES;

    } else if ([_annotationsForClustering containsObject:annotation]) {
    
        [_annotationsForClustering removeObject:annotation];
    
    } else if ([_annotations containsObject:annotation]) {
        
        [_annotations removeObject:annotation];
        
    }

    [super removeAnnotation:annotation];
    
    return needToReload;
}

- (void)removeAnnotations:(NSArray *)annotations
{
    BOOL needToReload = NO;
    
    for (id<MKAnnotation> annotation in annotations) {
        
        if ([self removeAnnotationFromCache:annotation] ){
            needToReload = YES;
        }
        
    }
    
    if (needToReload){
        [self resetClusterAnnotations];
        [self calculateClusterAnnotations];
    }
}

- (void)removeAllAnnotations
{
    [self removeAnnotations:self.annotations];
}

- (void)resetClusterAnnotations
{
    [_clusterOperationQueue cancelAllOperations];

    [super removeAnnotations:_annotationsClustered];
    [_annotationsClustered removeAllObjects];
    
    [_storageMapView removeAnnotations:_storageMapView.annotations];
    [_storageMapView addAnnotations:_annotationsForClustering];    
}

- (void)calculateClusterAnnotations
{
    MKMapRect visibleMapRect = self.visibleMapRect;
    visibleMapRect = MKMapRectMake(visibleMapRect.origin.x - visibleMapRect.size.width / 2,
                                   visibleMapRect.origin.y - visibleMapRect.size.height / 2,
                                   visibleMapRect.size.width * 2,
                                   visibleMapRect.size.height * 2);
    
    NSSet *visibleAnnotations = [_storageMapView annotationsInMapRect:visibleMapRect];
    [_storageMapView removeAnnotations:[visibleAnnotations allObjects]];
    
    RWClusterOperation *clusterOperation = [[RWClusterOperation alloc] initWithMapView:self
                                                                           annotations:[visibleAnnotations allObjects]
                                                                            completion:^(NSArray *clusterAnnotations)
                                            {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [_annotationsClustered addObjectsFromArray:clusterAnnotations];
                                                    [super addAnnotations:clusterAnnotations];
                                                });
                                            }];
    
    [_clusterOperationQueue addOperation:clusterOperation];
    
}

- (NSInteger)zoomLevelForMapRect:(MKMapRect)mapRect
{
    CGFloat maxSide = MAX(mapRect.size.width, mapRect.size.height);
    
    CGFloat worldSide;
    
    if (maxSide == mapRect.size.width) {
        worldSide = MKMapRectWorld.size.width;
    } else {
        worldSide = MKMapRectWorld.size.height;
    }
    
    double zoomLevel = worldSide / maxSide;
    zoomLevel = floor(log2(zoomLevel));
    
    return zoomLevel;
}

- (MKMapRect)mapRectForZoomLevel:(NSInteger)zoomLevel
{
    double width = MKMapRectWorld.size.width / pow(2, zoomLevel);
    double height = MKMapRectWorld.size.height / pow(2, zoomLevel);
    
    MKMapPoint centerPoint = MKMapPointForCoordinate(self.centerCoordinate);
    
    MKMapRect mapRect = MKMapRectMake(centerPoint.x - width / 2,
                                      centerPoint.y - height / 2,
                                      width,
                                      height);
    return mapRect;
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
        
        if (_annotationsForClustering.count != 0) {
            [self resetClusterAnnotations];
        }
        
    }
    
    if (_annotationsForClustering.count != 0) {
        [self calculateClusterAnnotations];
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
    if ([view conformsToProtocol:@protocol(RWAnnotationView)]) {
        
        if ([view respondsToSelector:@selector(shouldShowCalloutView)]) {
        
            if ([(id<RWAnnotationView>)view shouldShowCalloutView:self]) {
                                
                if ([_delegate respondsToSelector:@selector(mapView:calloutAnnotationForAnnotationView:)]) {
                
                    _calloutAnnotation = [_delegate mapView:mapView calloutAnnotationForAnnotationView:view];
                    [self addAnnotation:_calloutAnnotation];
                    
                }
                
            }
            
        }
        
    }
    
    if ([_delegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
        [_delegate mapView:mapView didSelectAnnotationView:view];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if (view == _calloutAnnotation.parentAnnotationView) {
        [self removeAnnotation:_calloutAnnotation];
    }
    
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