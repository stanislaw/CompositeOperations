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

@property (strong, nonatomic) NSMutableArray *operations;

- (void)runNextOperation:(COOperation *)lastFinishedOperationOrNil;

@end

@implementation COSequentialOperation

- (id)init {
    self = [super init];

    if (self == nil) return nil;

    _operations = [NSMutableArray new];
    _delegate   = self;

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

    COOperation *nextOperation = [self.delegate sequentialOperation:self
                                        nextOperationAfterOperation:lastFinishedOperationOrNil];

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

- (COOperation *)sequentialOperation:(COSequentialOperation *)sequentialOperation
         nextOperationAfterOperation:(NSOperation<COOperation> *)lastFinishedOperationOrNil {
    @throw [NSException exceptionWithName:NSGenericException reason:@"Must override in subclass or implement in external delegate" userInfo:nil];
    
    return nil;
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
