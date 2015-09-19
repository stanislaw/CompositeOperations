//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COOperation.h"

FOUNDATION_EXPORT NSString *const COParallelOperationErrorsKey;

@protocol COParallelTask <NSObject>
- (NSArray *)operations;
@end

@interface COParallelOperation : COOperation
- (id)initWithParallelTask:(id <COParallelTask>)parallelTask;
- (id)initWithOperations:(NSArray *)operations;
@end
