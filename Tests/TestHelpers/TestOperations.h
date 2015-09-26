//
//  TestOperations.h
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/CompositeOperations.h>

@interface OperationTriviallyReturningNull : COSimpleOperation
@end

@interface OperationTakingArrayAndAdding1ToIt : COSimpleOperation
- (id)initWithArray:(NSArray *)array;
@end

@interface OperationRejectingItself : COSimpleOperation
@end

@interface OperationRejectingItselfWithError : COSimpleOperation
- (id)initWithError:(NSError *)error;
@end
