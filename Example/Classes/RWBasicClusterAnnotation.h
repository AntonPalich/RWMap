//
//  RWBasicClusterAnnotation.h
//  RWMapExample
//
//  Created by Anton Schukin on 10/26/12.
//  Copyright (c) 2012 RealWeb. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RWClusterAnnotation.h"
#import "RWBasicAnnotation.h"

@interface RWBasicClusterAnnotation : RWBasicAnnotation <RWClusterAnnotation>

@property (nonatomic, strong) NSArray *containedAnnotations;

- (id)initWithContainedAnnotations:(NSArray *)containedAnnotations;

@end
