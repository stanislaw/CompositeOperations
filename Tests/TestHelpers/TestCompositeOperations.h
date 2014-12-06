//
//  TestCompositeOperations.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "CompositeOperations.h"

@interface SequenceOfThreeTrivialGreenOperations : NSObject <COSequence>
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@interface SequenceWithFirstOperationRejectingItself : NSObject <COSequence>
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@interface TransactionOfThreeOperationsTriviallyReturningNull : NSObject <COTransaction>
@end

@interface TransactionWithOneOperationRejectingItself : NSObject <COTransaction>
@end

@interface TransactionWithOneOperationRejectingItselfWithGivenError : NSObject <COTransaction>
- (id)initWithError:(NSError *)error;
@property (readonly) NSError *error;
@end

@interface TransactionWithThreeSequentialOperationsEachWithThreeTrivialGreenOperations : NSObject <COTransaction>
@end
