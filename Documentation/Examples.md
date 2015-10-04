# CompositeOperations - Examples

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Simple Operation](#simple-operation)
- [Composite Operation](#composite-operation)
    - [Parallel Composition](#parallel-composition)
    - [Sequential Composition](#sequential-composition)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Simple Operation

```objective-c
#import <CompositeOperations/COSimpleOperation.h>

@interface SimpleOperation : COSimpleOperation
@end

@implementation SimpleOperation
- (void)main {
    [DoSomeThingAsynchronousWithCompletionHandler:^(id result, NSError *error){
        if (result) {
            [self finishWithResult:result];
        } else {
        	[self rejectWithError:error];
        }
    }];
}
@end

...

#import "SimpleOperation.h"

SimpleOperation *simpleOperation = [SimpleOperation new];

simpleOperation.completion = ^(id result, NSError *error) {
    if (result) {
        // handle result
    } else {
        // handle error
    }
};

[[NSOperationQueue mainQueue] addOperation:simpleOperation];
```

## Composite Operation

#### Parallel Composition

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

#### Sequential Composition

```objective-c
@interface COSimpleSequence : NSObject
@end

@implementation COSimpleSequence

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

COSimpleSequence *sequence = [COSimpleSequence new];

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
