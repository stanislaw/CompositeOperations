//
// CompositeOperations
//
// CompositeOperations/COSequence.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>
#import <CompositeOperations/COOperation.h>

@protocol COSequence <NSObject>

- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation <COOperation> *)previousOperationOrNil;

@end
