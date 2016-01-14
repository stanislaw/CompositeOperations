//
// CompositeOperations
//
// CompositeOperations/COSequence.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COSequence.h>

@interface CORetrySequence ()
@property (assign, nonatomic) NSUInteger numberOfRetries;
@property (readonly, nonatomic) NSOperation <COOperation> *operation;
@end

@implementation CORetrySequence

@synthesize numberOfRetries = _numberOfRetries;

- (id)initWithOperation:(NSOperation <COOperation, NSCopying> *)operation
        numberOfRetries:(NSUInteger)numberOfRetries {
    
    if (numberOfRetries == 0) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:@"numberOfRetries must be a positive value"
                                     userInfo:nil];
    }

    self = [super init];

    _operation = operation;
    _numberOfRetries = numberOfRetries;

    return self;
}

- (NSOperation<COOperation> *)nextOperationAfterOperation:(NSOperation<COOperation> *)previousOperationOrNil {

    if (previousOperationOrNil && previousOperationOrNil.result) {
        return nil;
    }

    if (self.numberOfRetries > 0) {
        self.numberOfRetries--;

        return previousOperationOrNil ? [previousOperationOrNil copy] : self.operation;
    } else {
        return nil;
    }
}

@end
