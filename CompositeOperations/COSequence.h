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

typedef NSOperation<COOperation> * _Nullable (^COStepGenerator)(NSOperation<COOperation> * _Nullable);

@protocol COSequence <NSObject>
- (NSOperation <COOperation> * _Nullable)nextOperationAfterOperation:(NSOperation <COOperation> *_Nullable)previousOperationOrNil;
@end

@interface CORetrySequence : NSObject <COSequence>
- (nonnull id)initWithOperation:(nonnull NSOperation <COOperation, NSCopying> *)operation
                numberOfRetries:(NSUInteger)numberOfRetries;
@end
