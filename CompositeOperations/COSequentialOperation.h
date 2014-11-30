//
// CompositeOperations
//
// CompositeOperations/COSequentialOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COOperation.h"

@class COSequentialOperation;

FOUNDATION_EXPORT NSString *const COSequentialOperationErrorKey;

@protocol COSequentialOperationDelegate <NSObject>
- (COOperation *)sequentialOperation:(COSequentialOperation *)sequentialOperation
                       nextOperationAfterOperation:(COOperation *)lastFinishedOperationOrNil;
@end

@interface COSequentialOperation : COOperation <COSequentialOperationDelegate>
@property (weak, nonatomic) id <COSequentialOperationDelegate> delegate;
@end
