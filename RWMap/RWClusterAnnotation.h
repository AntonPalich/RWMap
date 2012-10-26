//
//  RWClusterAnnotation.h
//
//  Created by Anton Schukin on 10/16/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RWClusterAnnotation <MKAnnotation>

@property (nonatomic, strong) NSArray *containedAnnotations;

@end
