//
//  COCompositeOperation.m
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 19/09/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/COCompositeOperation.h>

#import "COSequentialOperation.h"
#import "COParallelOperation.h"

@interface COCompositeOperationCluster : COCompositeOperation
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation COCompositeOperation

- (id)init {
    if ([self isMemberOfClass:[COCompositeOperationCluster class]]) {
        @throw [NSException exceptionWithName:COGenericException reason:@"Must use one of designated initializers: initiWithSequentialTask:, initWithParallelTask:! or convenience initializer: initWithOperations:runInParallel:" userInfo:nil];
    }

    return [super init];
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    if (self != [COCompositeOperation class]) {
        return [super allocWithZone:zone];
    }

    static COCompositeOperationCluster *classCluster = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classCluster = [COCompositeOperationCluster alloc];
    });

    return classCluster;
}

@end

#pragma clang diagnostic pop

@implementation COCompositeOperationCluster

- (id)initWithSequentialTask:(id <COSequentialTask>)sequentialTask {
    NSParameterAssert(sequentialTask);

    return (id)[[COSequentialOperation alloc] initWithSequentialTask:sequentialTask];
}

- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel {
    if (parallel) {
        return (id)[[COParallelOperation alloc] initWithOperations:operations];
    } else {
        return (id)[[COSequentialOperation alloc] initWithOperations:operations];
    }
}

@end