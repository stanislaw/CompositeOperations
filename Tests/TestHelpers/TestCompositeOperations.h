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
