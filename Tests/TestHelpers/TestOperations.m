//
//  TestOperations.m
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "TestOperations.h"

@implementation OperationReturning1
- (void)main { [self finishWithResult:@(1)]; }
@end

@implementation OperationReturning2
- (void)main { [self finishWithResult:@(2)]; }
@end

@implementation OperationReturning3;
- (void)main { [self finishWithResult:@(3)]; }
@end

@implementation OperationReturningNull
- (void)main {
    [self finishWithResult:[NSNull null]];
}
- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] alloc] init];
}
@end

@implementation OperationPower2 {
    NSNumber *_number;
}

- (id)initWithNumber:(NSNumber *)number {
    self = [super init];

    _number = number;

    return self;
}

- (void)main {
    NSNumber *power2 = @(_number.integerValue * _number.integerValue);

    [self finishWithResult:power2];
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
    NSError *error = [NSError errorWithDomain:@"Foo" code:0 userInfo:nil];

    [self rejectWithError:error];
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
