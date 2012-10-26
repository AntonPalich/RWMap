//
//  RWMapViewController.h
//  RWMapExample
//
//  Created by Anton Schukin on 10/23/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RWMapView.h"

@interface RWMapViewController : UIViewController <RWMapViewDelegate>

@property (nonatomic, readonly) IBOutlet UIView *propertiesView;

@property (nonatomic, readonly) IBOutlet UILabel *zoomValueLabel;
@property (nonatomic, readonly) IBOutlet UILabel *centerLatitudeLabel;
@property (nonatomic, readonly) IBOutlet UILabel *centerLongitudeLabel;
@property (nonatomic, readonly) IBOutlet UILabel *spanLatitudeLabel;
@property (nonatomic, readonly) IBOutlet UILabel *spanLongitudeLabel;

@property (nonatomic, readonly) IBOutlet RWMapView *mapView;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

@end
