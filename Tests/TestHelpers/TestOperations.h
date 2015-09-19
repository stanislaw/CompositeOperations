//
//  TestOperations.h
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/CompositeOperations.h>

@interface OperationTriviallyReturningNull : COOperation
@end

@interface OperationTakingArrayAndAdding1ToIt : COOperation
- (id)initWithArray:(NSArray *)array;
@end

@interface OperationRejectingItself : COOperation
@end

@interface OperationRejectingItselfWithError : COOperation
- (id)initWithError:(NSError *)error;
@end
