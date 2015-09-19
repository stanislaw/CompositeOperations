//
// CompositeOperations
//
// CompositeOperations/COSequentialOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COSequentialOperation.h>

NSString *const COSequentialOperationErrorKey = @"COSequentialOperationErrorKey";

@interface COSequentialOperation ()

@property (strong, nonatomic) id <COSequentialTask> sequentialTask;
@property (strong, nonatomic) NSMutableArray *operations;

- (void)runNextOperation:(COOperation *)lastFinishedOperationOrNil;

@end

@interface COSimpleSequentialTask : NSObject <COSequentialTask>
- (id)initWithOperations:(NSArray *)operations;
@end

@implementation COSequentialOperation

- (id)init {
    @throw [NSException exceptionWithName:COErrorDomain reason:@"Must use designated initializer initWithSequentialTask:!" userInfo:nil];

    return nil;
}

- (id)initWithSequentialTask:(id<COSequentialTask>)sequentialTask {
    NSParameterAssert([sequentialTask conformsToProtocol:@protocol(COSequentialTask)]);

    self = [super init];

    if (self == nil) return nil;

    _operations = [NSMutableArray new];
    _sequentialTask = sequentialTask;

    return self;
}

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    COSimpleSequentialTask *sequentialTask = [[COSimpleSequentialTask alloc] initWithOperations:operations];

    self = [self initWithSequentialTask:sequentialTask];

    if (self == nil) return nil;

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

    COOperation *nextOperation = [self.sequentialTask nextOperationAfterOperation:lastFinishedOperationOrNil];

    if (nextOperation) {
        [self.operations addObject:nextOperation];

        __weak COSequentialOperation *weakSelf = self;
        __weak COOperation *weakNextOperation = nextOperation;

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

@interface COSimpleSequentialTask ()
@property (readonly, nonatomic) NSArray *operations;
@property (readonly, nonatomic) NSEnumerator *enumerator;
@end

@implementation COSimpleSequentialTask

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    self = [super init];

    if (self == nil) return nil;

    _operations = operations;
    _enumerator = [operations objectEnumerator];

    return self;
}

- (COOperation *)nextOperationAfterOperation:(COOperation *)previousOperationOrNil {
    return [self.enumerator nextObject];
}

@end