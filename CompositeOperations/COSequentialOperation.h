//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COOperation.h"

@interface COSequentialOperation : COOperation
- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil;
@end
