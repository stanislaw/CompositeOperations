//
//  TestOperations.m
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "TestOperations.h"

@implementation OperationTriviallyReturningNull
- (void)main {
    [self finish];
}
@end

@implementation OperationTakingArrayAndAdding1ToIt {
    NSArray *_array;
}

- (id)initWithArray:(NSArray *)array {
    NSParameterAssert(array);

    self = [super init];

    _array = array;

    return self;
}

- (void)main {
    id result = [_array arrayByAddingObject:@(1)];

    [self finishWithResult:result];
}

@end

@implementation OperationRejectingItself
- (void)main {
    [self reject];
}
@end

@implementation OperationRejectingItselfWithError {
    NSError *_error;
}
- (id)initWithError:(NSError *)error {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _error = error;

    return self;
}

- (void)main {
    [self rejectWithError:_error];
}
@end
