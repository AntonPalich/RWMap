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
@property (nonatomic, readonly) IBOutlet RWMapView *mapView;

@end
