//
// CompositeOperations
//
// CompositeOperations/__COParallelOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COCompositeOperation.h>

@interface __COParallelOperation : COCompositeOperation
- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations NS_DESIGNATED_INITIALIZER;
- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations runInParallel:(BOOL)parallel NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
@end
