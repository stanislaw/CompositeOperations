//
// CompositeOperations
//
// CompositeOperations/COCompositeOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COTypedefs.h>
#import <CompositeOperations/COAbstractOperation.h>
#import <CompositeOperations/COSequence.h>

@interface COCompositeOperation : COAbstractOperation

@property (readonly, nullable) NSArray *result;
@property (readonly, nullable) NSArray <NSError *> *error;

@property (copy, nullable) void (^completion)(NSArray * _Nullable results, NSArray <NSError *> * _Nullable errors);

// Parallel flow
- (nonnull id)initWithOperations:(nonnull NSArray <NSOperation <COOperation> *> *)operations
                  operationQueue:(nonnull NSOperationQueue *)operationQueue;

- (nonnull id)initWithOperations:(nonnull NSArray <NSOperation <COOperation> *> *)operations;

// Sequential flow
- (nonnull id)initWithSequence:(nonnull id<COSequence>)sequence;

@end
