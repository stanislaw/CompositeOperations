//
//  TestCompositeOperations.h
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/CompositeOperations.h>

@interface SequenceOfThreeTrivialGreenOperations : NSObject <COSequentialTask>
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@interface SequenceWithFirstOperationRejectingItself : NSObject <COSequentialTask>
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@interface TransactionOfThreeOperationsTriviallyReturningNull : NSObject <COParallelTask>
@end

@interface TransactionWithOneOperationRejectingItself : NSObject <COParallelTask>
@end

@interface TransactionWithOneOperationRejectingItselfWithGivenError : NSObject <COParallelTask>
- (id)initWithError:(NSError *)error;
@property (readonly) NSError *error;
@end

@interface TransactionWithThreeSequentialOperationsEachWithThreeTrivialGreenOperations : NSObject <COParallelTask>
@end
