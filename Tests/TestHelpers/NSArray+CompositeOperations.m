//
//  NSArray+CompositeOperations.m
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 18/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "NSArray+CompositeOperations.h"

@implementation NSArray (CompositeOperations)

- (NSUInteger)countForObject:(id)anObject {
    NSIndexSet *indexesOfObject = [self indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqual:anObject];
    }];

    return indexesOfObject.count;
}

@end
