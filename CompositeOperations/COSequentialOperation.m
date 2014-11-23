//
// CompositeOperations
//
// CompositeOperations/COSequentialOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COSequentialOperation.h"
#import "COOperation_Private.h"

@interface COSequentialOperation ()

@property (strong, nonatomic) NSMutableArray *operations;

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil;

@end

@implementation COSequentialOperation

- (id)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _operations = [NSMutableArray new];
    _delegate   = self;

    return self;
}

- (void)main {
    [self runNextOperation:nil];
}

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil {
    if (self.isCancelled ||
        (lastFinishedOperationOrNil && lastFinishedOperationOrNil.isCancelled)) {

        NSError *error = lastFinishedOperationOrNil.error;

        if (error) {
            [self rejectWithError:error];
        } else {
            [self reject];
        }

        return;
    }

    NSOperation <COOperation> *nextOperation = [self.delegate sequentialOperation:self
                                                      nextOperationAfterOperation:lastFinishedOperationOrNil];

    if (nextOperation) {
        [self.operations addObject:nextOperation];

        __weak COSequentialOperation *weakSelf = self;
        __weak NSOperation <COOperation> *weakNextOperation = nextOperation;

        nextOperation.completionBlock = ^{
            if (weakNextOperation.error) {
                [weakSelf rejectWithError:weakNextOperation.error];
                return;
            }

            else if (weakNextOperation.isCancelled) {
                [weakSelf reject];
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf runNextOperation:weakNextOperation];
            });
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            [nextOperation start];
        });
    } else {
        [self finishWithResult:lastFinishedOperationOrNil.result];
    }
}

- (NSOperation <COOperation> *)sequentialOperation:(COSequentialOperation *)sequentialOperation
                       nextOperationAfterOperation:(NSOperation<COOperation> *)lastFinishedOperationOrNil {
    @throw [NSException exceptionWithName:NSGenericException reason:@"Must override in subclass or implement in external delegate" userInfo:nil];
    
    return nil;
}

@end
