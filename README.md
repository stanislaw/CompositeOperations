# CompositeOperations 

You might be interested in this project if you use GCD and/or NSOperation but want them to be on a higher level of abstraction: you need to implement the complex flows of operations and for some reasons you are not satisfied with what GCD/NSOperation/NSOperationQueue can do out of a box.

Key features:
 
* Composition of operations, two types: sequential and parallel composition.
* Mixing (or combining) composite operations into each other.
* Full NSOperation/NSOperationQueue compatibility: all operations are NSOperation subclasses and can be be run inside NSOperationQueue queues.

<!-- [![Build Status](https://travis-ci.org/stanislaw/CompositeOperations.png?branch=master)](https://travis-ci.org/stanislaw/CompositeOperations) -->

## Status 2015.10.04

The project has alpha status. 

## Installation

### Framework

Latest framework binaries can be found on [Releases](https://github.com/stanislaw/CompositeOperations/releases) page.

### Cocoa Pod

```
pod 'CompositeOperations', :git => 'https://github.com/stanislaw/CompositeOperations.git', :tag => '0.8.1'
```

## Usage

Composite Operations has two types of operations: simple - `COSimpleOperation` and composite - `COCompositeOperation` which both conform to `<COOperation>` protocol (see [diagram](CompositeOperations-Diagram.svg)). 

This conformance basically means that both operations when finished have 3 possible states: 

1. a non-empty `result` field indicates success
2. a non-empty `error` field indicates failure
3. both empty `result` and `error` fields indicate that operation was cancelled from outside (using `-[NSOperation cancel]` method).

Operation can never have both `result` and `error` fields non-empty!

This convention allows Composite Operations to decide at a certain point whether to continue execution of particular group of operations or to stop it. For operations without a specific result `[NSNull null]` should be passed as result.

### COSimpleOperation

In a nutshell COSimpleOperation is a NSOperation with a bit of convenience sugar on top of it. As an operational unit for composite operations it usually corresponds to one networking request or some small focused piece of work.

```objective-c
@interface SimpleOperation : COSimpleOperation
@end

@implementation SimpleOperation
- (void)main {
    [DoSomethingAsynchronousWithCompletionHandler:^(id result, NSError *error){
        if (result) {
            [self finishWithResult:result];
        } else {
            [self rejectWithError:error];
        }
    }];
}
@end
```

To access operation's results `completion` convenience property is used, it is called after NSOperation's @completionBlock is executed.

```objective-c
simpleOperation.completion = ^(id result, NSError *error) {
    if (result) {
        // handle result
    } 
    
    else if (error) {
        // handle error
    }
    
    else {
    	// operation was cancelled
    }
};
```

### COCompositeOperation

COCompositeOperation supports two types of composition: parallel and sequential.

#### Parallel composition

Parallel type of composition implies that when parallel operation starts, all its sub-operations are executed in parallel. Parallel composite operation succeeds if and only if all of its sub-operations succeed and vice versa it fails if at least one of sub-operation fails. There is important difference in how COCompositeOperation produces its result or error compared to COSimpleOperation - its result and error are results or errors accumulated from all sub-operations so they both are NSArrays.

```objective-c
NSArray *operations = @[ operation1, operation2, operation3 ]; // each operation is NSOperation <COOperation> *

COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithOperations:operations];

parallelOperation.completion = ^(NSArray *results, NSArray *errors) {
    if (results) {
        // handle results
    } 
    
    else if (error) {
        // handle errors
    }
    
    else {
        // handle cancellation: operation was cancelled from outside    }
};

[[NSOperationQueue mainQueue] addOperation:parallelOperation];
```

#### Sequential composition

Sequential composition implies sequential flow: sub-operations are executed serially one after another. Sequencing is achieved by collaboration between COCompositeOperation and arbitrary class conforming to `COSequence` protocol which is used by composite operation as a delegate who decides what operations are and in which order to run them:

```objective-c
#import "OperationsRepository.h"

@interface SimpleSequence : NSObject <COSequence>
@property (readonly, nonatomic) OperationsRepository *repository;
@end

@implementation SimpleSequence

- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation <COOperation> *)previousOperationOrNil {

    // Nothing behind - it will be the first operation in sequence
    if (previousOperationOrNil == nil)) {
        return [self.repository operation1]; // returns created operation1
    }

    // Operation2 follows after Operation1 if that was successful
    if ([previousOperationOrNil isKindOfClass:[Operation1 class]] &&
        previousOperationOrNil.result) {
        id resultOfOperation1 = previousOperationOrNil.result;

        return [self.repository operation2ForResultOfOperation1:result]; // returns created operation2
    }

    // Returning nil tells composite operation that we are done
    return nil;
}

@end

SimpleSequence *sequence = [SimpleSequence new];

COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequence:sequence];

sequentialOperation.completion = ^(NSArray *results, NSArray *errors) {
    if (results) {
        // handle results
    } 
    
    else if (error) {
        // handle errors
    }
    
    else {
        // handle cancellation    	    }
};

[[NSOperationQueue mainQueue] addOperation:sequentialOperation];
```

## Design principles

- Simple operation or root composite operation that are created must be retained. The most natural way of doing it is to run operations in NSOperationQueues though it is also possible to retain operation as `@property (strong)` field.
- Use `@completion` of both COSimpleOperation and COCompositeOperation, do not use `NSOperation@completionBlock`.
- Use `cancel` to cancel operation from outside. To stop operation's execution from inside always use `reject`.

## Examples

See [Documentation/Examples](Documentation/Examples.md).

Also see DevelopmentApp project and `Example` target in it.

## Related

* [WWDC 2015 - Advanced NSOperations](https://developer.apple.com/videos/play/wwdc2015-226/)

## Copyright

Copyright (c) 2014 Stanislaw Pankevich. See LICENSE for details.

