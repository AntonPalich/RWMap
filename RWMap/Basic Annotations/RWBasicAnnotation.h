//
//  RWBasicAnnotation.h
//
//  Created by Anton Schukin on 10/26/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RWBasicAnnotation : NSObject <MKAnnotation> {
    
    CLLocationCoordinate2D _coordinate;
    NSString *_title;
    NSString *_subtitle;
    
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

- (void)setTitle:(NSString *)title;
- (void)setSubtitle:(NSString *)subtitle;

@end
