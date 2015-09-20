//
// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COCompositeOperation.h>

#import "COSequentialOperation.h"
#import "COParallelOperation.h"

NSString *const COCompositeOperationErrorKey = @"COSequentialOperationErrorKey";

@interface COCompositeOperationCluster : COCompositeOperation
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation COCompositeOperation

- (id)init {
    if ([self isMemberOfClass:[COCompositeOperationCluster class]]) {
        @throw [NSException exceptionWithName:COGenericException reason:@"Must use one of designated initializers: initWithOperations:runInParallel: or initiWithSequence:" userInfo:nil];
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

- (id)initWithSequence:(id <COSequence>)sequence {
    NSParameterAssert(sequence);

    return (id)[[COSequentialOperation alloc] initWithSequence:sequence];
}

- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel {
    if (parallel) {
        return (id)[[COParallelOperation alloc] initWithOperations:operations];
    } else {
        return (id)[[COSequentialOperation alloc] initWithOperations:operations];
    }
}

@end