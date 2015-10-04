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

This conformance basically means that both operations when finished have **either** a non-empty `result` field or non-empty `error` field and never both i.e. finished operation can only be in valid state (presence of result indicates that) or in invalid state (absence of result, presence of error). This convention allows Composite Operations to decide at a certain point whether to continue execution of particular group of operations or to stop it. For operations without a specific result `[NSNull null]` should be passed as result.

### COSimpleOperation

In a nutshell COSimpleOperation is a NSOperation with a bit of convenience sugar on top of it. As an operational unit for composite operations it usually corresponds to one networking request or some small focused piece of work.

```objective-c
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

To access operation's results `completion` convenience property is used:

```objective-c
simpleOperation.completion = ^(id result, NSError *error) {
    if (result) {
        // handle result
    } else {
        // handle error
    }
};
```

### COCompositeOperation

COCompositeOperation supports two types of composition: parallel and sequential.

#### Parallel composition

Parallel type of composition implies that parallel composite operation succeeds if and only if all of its sub-operations succeed and vice versa it fails if at least one of sub-operation fails. There is important difference in how COCompositeOperation produces its result or error compared to COSimpleOperation - its result and error are results or errors accumulated from all sub-operations so they both are NSArrays.

```objective-c
NSArray *operations = @[ operation1, operation2, operation3 ]; // each operation is NSOperation <COOperation> *

COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithOperations:operations];

parallelOperation.completion = ^(NSArray *results, NSArray *errors) {
    if (results) {
        // handle results
    } else {
        // handle errors
    }
};

[[NSOperationQueue mainQueue] addOperation:parallelOperation];
```

#### Sequential composition

Sequential composition is achieved by collaboration between COCompositeOperation and arbitrary class conforming to `COSequence` protocol which is used by composite operation as a delegate who decides what operations and in which order to run:

```objective-c
@interface SimpleSequence : NSObject <COSequence>
@end

@implementation SimpleSequence

- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation <COOperation> *)previousOperationOrNil {

    // Nothing behind - it will be the first operation in sequence
    if (previousOperationOrNil == nil)) {
        return [Operation1 new];
    }

    // Operation2 follows after Operation1 if that was successful
    if ([previousOperationOrNil isKindOfClass:[Operation1 class]] &&
        previousOperationOrNil.result) {
        id resultOfOperation1 = previousOperationOrNil.result;

        return [[Operation2 alloc] initWithResultOfOperation1:result];
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
    } else {
        // handle errors
    }
};

[[NSOperationQueue mainQueue] addOperation:sequentialOperation];
```

## Examples

See [Documentation/Examples](Documentation/Examples.md).

Also see DevelopmentApp project and Example target in it.

## Copyright

Copyright (c) 2014 Stanislaw Pankevich. See LICENSE for details.

