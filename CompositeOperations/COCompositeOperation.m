//
//  COCompositeOperation.m
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 19/09/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/COCompositeOperation.h>

@interface COCompositeOperationCluster : COCompositeOperation
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation COCompositeOperation

- (id)init {
    @throw [NSException exceptionWithName:COErrorDomain reason:@"Must use designated initializer initiWithSequentialTask: initWithParallelTask:!" userInfo:nil];

    return nil;
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

- (id)initWithParallelTask:(id <COParallelTask>)parallelTask {
    NSParameterAssert(parallelTask);

    return (id)[[COParallelOperation alloc] initWithParallelTask:parallelTask];
}

- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel {
    if (parallel) {
        return (id)[[COParallelOperation alloc] initWithOperations:operations];
    } else {
        return (id)[[COSequentialOperation alloc] initWithOperations:operations];
    }
}

@end