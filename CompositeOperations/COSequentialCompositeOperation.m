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

- (void)runNextOperation:(id)lastFinishedOperationOrNil {
    id nextOperation = [self nextOperationAfterOperation:lastFinishedOperationOrNil];

    if (nextOperation) {
        [self.operations addObject:nextOperation];

        [nextOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];

        [(COOperation *)nextOperation start];
    } else {
        [self finish];
    }
}

- (id)nextOperationAfterOperation:(id)lastFinishedOperationOrNil {
    @throw [NSException exceptionWithName:NSGenericException reason:@"Must override in subclass" userInfo:nil];
    
    return nil;
}

- (void)operationDidFinish:(id)operation {
    [self runNextOperation:operation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    BOOL finished = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];

    if (finished) {
        [self operationDidFinish:object];
    }
}

@end
