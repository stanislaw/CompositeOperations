//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COCompositeOperation.h>

FOUNDATION_EXPORT NSString *const COParallelOperationErrorsKey;

@interface COParallelOperation : COCompositeOperation
- (id)initWithOperations:(NSArray *)operations NS_DESIGNATED_INITIALIZER;
- (id)initWithParallelTask:(id <COParallelTask>)parallelTask;
- (id)init NS_UNAVAILABLE;
@end
