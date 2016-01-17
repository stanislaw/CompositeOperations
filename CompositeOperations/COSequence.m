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

@interface COLinearSequence ()
@property (assign, nonatomic) NSUInteger currentStepIndex;
@end

@implementation COLinearSequence

- (instancetype)init {
    self = [super init];

    _currentStepIndex = 0;

    return self;
}

- (nonnull NSArray <COLinearSequenceStep>*)steps {
    NSString *reason = [NSString stringWithFormat:@"Must override -steps method in a subclass!"];

    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];

    return nil;
}

- (NSOperation <COOperation> * _Nullable)nextOperationAfterOperation:(NSOperation <COOperation> *_Nullable)previousOperationOrNil {

    // Linear sequence works only with successful operations
    if (previousOperationOrNil && previousOperationOrNil.result == nil) {
        return nil;
    }

    NSInteger currentStepIndex = self.currentStepIndex++;

    if (currentStepIndex < self.steps.count) {
        COLinearSequenceStep currentStep = self.steps[currentStepIndex];

        NSOperation<COOperation> *nextOperation = currentStep(previousOperationOrNil);

        return nextOperation;
    }

    return nil;
}

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
