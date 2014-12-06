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

@protocol COTransaction <NSObject>
- (NSArray *)operations;
@end

@interface COParallelOperation : COOperation
- (id)initWithTransaction:(id <COTransaction>)transaction;
@end
