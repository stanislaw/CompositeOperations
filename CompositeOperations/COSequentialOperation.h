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

@protocol COSequentialOperationDelegate <NSObject>
- (NSOperation <COOperation> *)sequentialOperation:(COSequentialOperation *)sequentialOperation
                       nextOperationAfterOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil;
@end

@interface COSequentialOperation : COOperation <COSequentialOperationDelegate>
@property (weak, nonatomic) id <COSequentialOperationDelegate> delegate;
@end
