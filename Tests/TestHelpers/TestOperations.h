//
//  TestOperations.h
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/CompositeOperations.h>

@interface OperationReturning1 : COSimpleOperation; @end
@interface OperationReturning2 : COSimpleOperation; @end
@interface OperationReturning3 : COSimpleOperation; @end

@interface OperationReturningNull : COSimpleOperation <NSCopying>
@end

@interface OperationPower2 : COSimpleOperation
- (id)initWithNumber:(NSNumber *)number;
@end

@interface OperationTakingArrayAndAdding1ToIt : COSimpleOperation
- (id)initWithArray:(NSArray *)array;
@end

@interface OperationRejectingItself : COSimpleOperation
@end

@interface OperationRejectingItselfWithError : COSimpleOperation
- (id)initWithError:(NSError *)error;
@end
