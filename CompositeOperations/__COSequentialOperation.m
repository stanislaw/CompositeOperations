//
// CompositeOperations
//
// CompositeOperations/__COSequentialOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "__COSequentialOperation.h"

#import "COAbstractOperation_Private.h"

@interface __COSequentialOperation ()

@property (strong, nonatomic) id<COSequence> sequence;
@property (readonly, nonatomic) NSMutableArray <NSOperation <COOperation> *> *operations;

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil;

@end

@implementation __COSequentialOperation

#pragma mark - <__COSequentialOperation>

- (id)initWithSequence:(nonnull id<COSequence>)sequence {
    NSParameterAssert([sequence conformsToProtocol:@protocol(COSequence)]);

    self = [super init];

    if (self == nil) return nil;

    _operations = [NSMutableArray new];
    _sequence = sequence;

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

        __weak __COSequentialOperation *weakSelf = self;
        __weak NSOperation <COOperation> *weakNextOperation = nextOperation;

        nextOperation.completionBlock = ^{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [weakSelf runNextOperation:weakNextOperation];
            });
        };

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [nextOperation start];
        });
    } else {
        if (lastFinishedOperationOrNil && lastFinishedOperationOrNil.result == nil) {
            [self reject];

            return;
        }

        [self finish];
    }
}

- (void)finish {
    if (self.isCancelled == NO) {
        self.result = [self.operations valueForKey:@"result"];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(self.result, self.error);
    }
}

- (void)reject {
    if (self.isCancelled == NO) {
        NSArray *errors = [self.operations valueForKey:@"error"];

        self.error = errors;
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(nil, self.error);
    }
}

#pragma mark - NSObject

- (NSString *)debugDescription {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"name = %@; state = %@; isCancelled = %@; operations = %@; result = %@; error = %@", self.name, COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.operations, self.result, self.error]];

    NSString *description = [NSString stringWithFormat:@"<%@: %p (%@)>", NSStringFromClass([self class]), self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

#pragma mark - NSOperation

- (void)main {
    [self runNextOperation:nil];
}

@end
