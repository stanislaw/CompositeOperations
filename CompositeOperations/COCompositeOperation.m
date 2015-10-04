//
// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COCompositeOperation.h>

#import "__COSequentialOperation.h"
#import "__COParallelOperation.h"

NSString *const COCompositeOperationErrorKey = @"__COSequentialOperationErrorKey";

@interface __COCompositeOperation : COCompositeOperation
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation COCompositeOperation

@synthesize completion = _completion;

@dynamic result;
@dynamic error;

- (id)init {
    if ([self isMemberOfClass:[__COCompositeOperation class]]) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Must use one of initializers: initWithOperations:, initWithOperations:operationQueue: or initWithSequence:" userInfo:nil];
    }

    return [super init];
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    if (self != [COCompositeOperation class]) {
        return [super allocWithZone:zone];
    }

    static __COCompositeOperation *classCluster = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classCluster = [__COCompositeOperation alloc];
    });

    return classCluster;
}

@end

#pragma clang diagnostic pop

@implementation __COCompositeOperation

- (id)initWithOperations:(nonnull NSArray <NSOperation <COOperation> *> *)operations {
    return (id)[[__COParallelOperation alloc] initWithOperations:operations];
}

- (id)initWithOperations:(nonnull NSArray <NSOperation <COOperation> *> *)operations
          operationQueue:(nonnull NSOperationQueue *)operationQueue {
    return (id)[[__COParallelOperation alloc] initWithOperations:operations
                                                  operationQueue:operationQueue];
}

- (id)initWithSequence:(nonnull id<COSequence>)sequence {
    NSParameterAssert(sequence);

    return (id)[[__COSequentialOperation alloc] initWithSequence:sequence];
}

@end
