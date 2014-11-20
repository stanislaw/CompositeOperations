//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COSequentialOperation.h"
#import "COOperation_Private.h"

@interface COSequentialOperation ()
@property (strong, nonatomic) NSMutableArray *operations;

- (void)runNextOperation:(NSOperation <COOperation> *)lastFinishedOperationOrNil;
- (void)operationDidFinish:(NSOperation <COOperation> *)operation;

@end

@implementation COSequentialOperation

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
    if (operation.error) {
        [self rejectWithError:operation.error];
        return;
    }

    else if (operation.isCancelled) {
        [self reject];
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
        [object removeObserver:self forKeyPath:keyPath];

        [self operationDidFinish:object];
    }
}

@end
