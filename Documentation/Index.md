# Documentation

* [What sync, async and composite means here? (Glossary)](Glossary.md)
* [Anatomy of four operations (in progress)](Anatomy.md)

## Introduction

The idea of this code comes from the logic of one iPhone app which involved a large number of complex (or "composite") operations, i.e. operations consisting of multiple sub-operations: sometimes these operations should have to be run strictly one after another, so that particular operation depends on the results of preceding operations ("cascaded flow") and sometimes it is needed to run two or three operations in a random order but having a completion handler called when all of these operations are done ("transactional flow").

The purpose of this code is to abstract the logic of these operations: two single operations (`COOperation` and `COSyncOperation`) and two complex (or "composite" which is better) operations (`COCascadeOperation` and `COTransactionalOperation`).

## Requirements

* Mac OS X 10.7, iOS 5.0.
* ARC

## Installation

Just add `CompositeOperations/` folder to your project.

Or add into your Podfile:

```ruby
pod 'CompositeOperations', :git => 'https://github.com/stanislaw/CompositeOperations'
pod update
```
 
In some common place like an app delegate set up default queue to be used by all non-sync operations:

```objective-c
#import <COQueues.h>
// ...
[COQueues setDefaultQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
```

Then import `CompositeOperations.h` where you want to use CO operations.

```objective-c
#import <CompositeOperations.h>
```

## CompositeOperations DSL

...

### Defining and running operations

Each of the operations can be run through its class initialization:

``` objective-c
#import "COSyncOperation.h"

// ...

COSyncOperation *syncOperation = [COSyncOperation new];

// Run immediatedly
[syncOperation run:^(COSyncOperation *so) {
    /* 
      ...Do something...
    */

    // And then somewhere explicitly finish operation:
    [so finish];
}];

// ...

// Or first prepare and then start manually:
syncOperation.operation = ^(COSyncOperation *so) {
    /*
      Do something
    */

    // Then finish:
    [so finish]
}

[syncOperation start];
```

or using helper functions defined in the global namespace in `CompositeOperations.h`:

``` objective-c
#import "CompositeOperations.h"

// ...

syncOperation(^(COSyncOperation *so) {
    /* 
      Do something...
    */
   
    // Then finish:
    [so finish];
});
```

## Finish rules.

Non-composite operations: `COOperation` and `COSyncOperation` must always be finished somewhere inside their operation blocks. 

Composite operations: transactional and cascade must not be finished since they automatically become finished when all their sub-operations are done.
 
## Combining operations

Both `COTransactionalOperation` and `COCascadedOperation` have a possibility to inject each other in their bodies: for example, if you inject transactional operation with a number of asynchronous tasks into a cascaded operation, then this transactional operation will be executed when its turn in cascade queue comes. Then, at the moment of its execution, the task will be performed in transactional manner - after that, when all transactional tasks finish their jobs, the flow will return to continue executing tasks in synchronous, ordered cascade queue. And opposite: if you add cascaded operation to the transaction operation - its task of running cascade will be dispatched asynchronously.

## Alternative tools

Any library implementing __Futures and promises__ pattern (http://en.wikipedia.org/wiki/Futures_and_promises can be a good alternative to this project. Author thinks it is just a matter of style and personal preferences.

* [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)

> A framework for composing and transforming streams of values

* [couchdeveloper/RXPromise](https://github.com/couchdeveloper/RXPromise)

> An Objective-C Class which implements the Promises/A+ specification.

