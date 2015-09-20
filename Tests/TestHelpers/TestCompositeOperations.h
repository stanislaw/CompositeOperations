//
//  TestCompositeOperations.h
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/CompositeOperations.h>

@interface Sequence_ThreeTrivialGreenOperations : NSObject <COSequence>
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@interface Sequence_FirstOperationRejects : NSObject <COSequence>
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@interface Sequence_FirstOperationRejects_3Attempts : NSObject <COSequence>
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end
