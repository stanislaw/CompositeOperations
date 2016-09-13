//
// CompositeOperations
//
// CompositeOperations/__COParallelOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COCompositeOperation.h"

@interface __COParallelOperation : COCompositeOperation

- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations
          operationQueue:(NSOperationQueue *)operationQueue;

- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations;

- (id)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
