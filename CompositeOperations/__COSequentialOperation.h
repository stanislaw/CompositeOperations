//
// CompositeOperations
//
// CompositeOperations/__COSequentialOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COCompositeOperation.h>

@interface __COSequentialOperation : COCompositeOperation
- (id)initWithSequence:(id<COSequence>)sequence NS_DESIGNATED_INITIALIZER;
- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations;
- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations runInParallel:(BOOL)parallel NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
@end
