//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COSequentialCompositeOperation.h"
#import "COOperation_Private.h"

@interface COSequentialCompositeOperation ()
@property (strong, nonatomic) NSMutableArray *operations;

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil;
- (void)operationDidFinish:(NSOperation <COOperation> *)operation;

@end

@implementation COSequentialCompositeOperation

- (id)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _operations = [NSMutableArray new];

    return self;
}

- (void)main {
    [self runNextOperation:nil];
}

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil {
    NSOperation <COOperation> *nextOperation = [self nextOperationAfterOperation:lastFinishedOperationOrNil];

    if (nextOperation) {
        [self.operations addObject:nextOperation];

        [nextOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];

        dispatch_async(dispatch_get_main_queue(), ^{
            [nextOperation start];
        });
    } else {
        [self finishWithResult:lastFinishedOperationOrNil.result];
    }
}

- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil {
    @throw [NSException exceptionWithName:NSGenericException reason:@"Must override in subclass" userInfo:nil];
    
    return nil;
}

- (void)operationDidFinish:(NSOperation <COOperation> *)operation {

    BOOL shouldFinishOperation = NO;

    if (operation.isCancelled) {
        shouldFinishOperation = YES;

        [self cancel];
    }

    if (operation.error) {
        shouldFinishOperation = YES;

        self.error = operation.error;
    }

    if (shouldFinishOperation) {
        [self finish];
        
        return;
    }

    [self runNextOperation:operation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    BOOL finished = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];

    if (finished) {
        [self operationDidFinish:object];

        [object removeObserver:self forKeyPath:keyPath];
    }
}

@end
