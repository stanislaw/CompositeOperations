//
//  TestCompositeOperations.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "CompositeOperations.h"

@interface SequentialCompositeOperationTrivialGreen : COSequentialCompositeOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@interface SequentialCompositeOperationWithFirstOperationRejectingItself : COSequentialCompositeOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end
