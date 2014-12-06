//
// CompositeOperations
//
// CompositeOperations/COSequentialOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COSequentialOperation.h"

NSString *const COSequentialOperationErrorKey = @"COSequentialOperationErrorKey";

@interface COSequentialOperation ()

@property (strong, nonatomic) id <COSequence> sequence;
@property (strong, nonatomic) NSMutableArray *operations;

- (void)runNextOperation:(COOperation *)lastFinishedOperationOrNil;

@end

@implementation COSequentialOperation

- (id)init {
    @throw [NSException exceptionWithName:COErrorDomain reason:@"Must use designated initializer initWithSequence:!" userInfo:nil];

    return nil;
}

- (id)initWithSequence:(id <COSequence>)sequence {
    NSParameterAssert([sequence conformsToProtocol:@protocol(COSequence)]);
    
    self = [super init];

    if (self == nil) return nil;

    _operations = [NSMutableArray new];
    _sequence   = sequence;

    return self;
}

- (void)main {
    [self runNextOperation:nil];
}

- (void)runNextOperation:(COOperation *)lastFinishedOperationOrNil {
    if (lastFinishedOperationOrNil && lastFinishedOperationOrNil.result == nil) {
        NSError *error = lastFinishedOperationOrNil.error;

        [self rejectWithError:error];

        return;
    }

    else if (self.isCancelled) {
        [self reject];

        return;
    }

    COOperation *nextOperation = [self.sequence nextOperationAfterOperation:lastFinishedOperationOrNil];

    if (nextOperation) {
        [self.operations addObject:nextOperation];

        __weak COSequentialOperation *weakSelf = self;
        __weak COOperation *weakNextOperation = nextOperation;

        nextOperation.completionBlock = ^{
            __strong COOperation *strongNextOperation = weakNextOperation;

            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf runNextOperation:strongNextOperation];
            });
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            [nextOperation start];
        });
    } else {
        if (lastFinishedOperationOrNil) {
            [self finishWithResult:lastFinishedOperationOrNil.result];
        } else {
            [self finish];
        }
    }
}

- (NSError *)resultErrorForError:(NSError *)error code:(NSUInteger)code userInfo:(NSDictionary *)userInfo {
    NSError *resultError;

    if (error) {
        resultError = [NSError errorWithDomain:COErrorDomain code:code userInfo:@{ COSequentialOperationErrorKey: error }];
    } else {
        resultError = [NSError errorWithDomain:COErrorDomain code:code userInfo:nil];
    }

    return resultError;
}

@end
