//
// CompositeOperations
//
// CompositeOperations/COSequentialOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COSequentialOperation.h"

@interface COSequentialOperation ()

@property (strong, nonatomic) id<COSequence> sequence;
@property (strong, nonatomic) NSMutableArray *operations;

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil;

@end

@interface COSimpleSequence : NSObject <COSequence>
- (id)initWithOperations:(NSArray *)operations;
@end

@implementation COSequentialOperation

- (id)initWithSequence:(id<COSequence>)sequence {
    NSParameterAssert([sequence conformsToProtocol:@protocol(COSequence)]);

    self = [super init];

    if (self == nil) return nil;

    _operations = [NSMutableArray new];
    _sequence = sequence;

    return self;
}

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    COSimpleSequence *sequence = [[COSimpleSequence alloc] initWithOperations:operations];

    self = [self initWithSequence:sequence];

    if (self == nil) return nil;

    return self;
}

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil {
    if (self.isCancelled) {
        [self reject];

        return;
    }

    NSOperation <COOperation> *nextOperation = [self.sequence nextOperationAfterOperation:lastFinishedOperationOrNil];

    if (nextOperation) {
        [self.operations addObject:nextOperation];

        __weak COSequentialOperation *weakSelf = self;
        __weak NSOperation <COOperation> *weakNextOperation = nextOperation;

        nextOperation.completionBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf runNextOperation:weakNextOperation];
            });
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            [nextOperation start];
        });
    } else {
        if (lastFinishedOperationOrNil) {
            if (lastFinishedOperationOrNil.result == nil) {
                NSError *error = lastFinishedOperationOrNil.error;

                [self rejectWithError:error];

                return;
            }

            [self finishWithResult:lastFinishedOperationOrNil.result];
        } else {
            [self finish];
        }
    }
}

#pragma mark - NSOperation

- (void)main {
    [self runNextOperation:nil];
}

@end

@interface COSimpleSequence ()
@property (readonly, nonatomic) NSArray *operations;
@property (readonly, nonatomic) NSEnumerator *enumerator;
@end

@implementation COSimpleSequence

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    self = [super init];

    if (self == nil) return nil;

    _operations = operations;
    _enumerator = [operations objectEnumerator];

    return self;
}

- (id <COOperation>)nextOperationAfterOperation:(id <COOperation>)previousOperationOrNil {
    if (previousOperationOrNil && previousOperationOrNil.result == nil) {
        return nil;
    }

    return [self.enumerator nextObject];
}

@end
