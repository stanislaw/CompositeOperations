//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COOperation.h>

FOUNDATION_EXPORT NSString *const COParallelOperationErrorsKey;

@protocol COParallelTask <NSObject>
- (NSArray *)operations;
@end

@interface COParallelOperation : COOperation
- (id)initWithOperations:(NSArray *)operations NS_DESIGNATED_INITIALIZER;
- (id)initWithParallelTask:(id <COParallelTask>)parallelTask;
- (id)init NS_UNAVAILABLE;
@end
