//
// CompositeOperations
//
// CompositeOperations/COSequence.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>
#import "COOperation.h"

@protocol COSequence <NSObject>
- (NSOperation <COOperation> * _Nullable)nextOperationAfterOperation:(NSOperation <COOperation> *_Nullable)previousOperationOrNil;
@end

typedef NSOperation <COOperation> *_Nullable(^COLinearSequenceStep)(NSOperation <COOperation> *_Nullable);

@interface COLinearSequence : NSObject <COSequence>
- (nonnull NSArray <COLinearSequenceStep>*)steps;
@end

@interface CORetrySequence : NSObject <COSequence>
- (nonnull id)initWithOperation:(nonnull NSOperation <COOperation, NSCopying> *)operation
                numberOfRetries:(NSUInteger)numberOfRetries;
@end
