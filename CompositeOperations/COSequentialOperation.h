//
// CompositeOperations
//
// CompositeOperations/COSequentialOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COOperation.h"

FOUNDATION_EXPORT NSString *const COSequentialOperationErrorKey;

@protocol COSequentialTask <NSObject>
- (COOperation *)nextOperationAfterOperation:(COOperation *)previousOperationOrNil;
@end

@interface COSequentialOperation : COOperation
- (id)initWithSequentialTask:(id <COSequentialTask>)sequentialTask;
@end
