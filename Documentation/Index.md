# Documentation

## What sync, async and composite means here?

The following words used here have their specific meaning in the context of this project: __sync__, __async__, __cascaded__, __transactional__, __composite__. 
 
__Sync__ The prefix "sync-" applied to some operation means, that this operation will be run synchronously: sync-operation will wait until the moment when something inside its operation block will explicitly finish it. It is important to note that sync-operation's operation block can contain any number of asynchronous jobs, queues switching and so on - sync-operation will just patiently stay waiting in its original queue/thread until the "finish" command is called from somewhere inside its operation body. 

The only known real use case for sync-operation is unit tests where it is often needed to straighten the curly flow of asynchronous jobs and perform some test assertions on the results of their execution before the test will run out.

Shortly: sync-operation runs operation and waits in the original queue/thread, it was called, to be finished from inside operation block. Addionally sync-operations can finish and rerun themselves in any given point of operation block (See "Each operation yields itself to the block").

__Async__ The prefix "async-" applied to some operation means, that this operation is dispatched immediatedly to some queue (default or a given) by dispatch_async (on which all async-operations in this project are based), so the meaning of "async-" corresponds to the what "async" means in "dispatch_async". 

__Transactional__ Transactional operation schedules the execution of a number of async sub-operations and runs a completion handler when they all finish their jobs. The key feature of transactional operation is that it doesn't care about the order in which its sub-operations run and finish themselves: completion handler is called at the moment when all of them will be done altoghether - after completion handler is called transactional operation finishes itself. 
 
`COTransactionalOperation` due to its async- nature does not block its original queue/thread (it just schedules sub-operations blocks there) but provides a completion handler instead, which is called when all sub-operations are over.

__Cascade__ Cascade of operations: execute a sub-set of operations strictly one after another. Very useful for the cases when each of the operations is based on the results of operations that had been completed before.

`COCascadeOperation` has async nature: in original queue/thread, in which it is run, it just schedules async sub-operations and runs the first sub-operation (leaving the original thread if the first sub-operation is scheduled to be run in some other queue). When the first sub-operation is over, it summons the second operation, second operation runs, finishes, summons the third and so on.  

__Composite__ In the context of this project "Composite operation" means "complex operation": transactional operation, cascaded operation, or their combination, "mixtum compositum" (See "Combining operations").

__Suboperations__ Both cascade and transactional operations schedule and run suboperations declared inside their bodies. Each suboperation block generates COOperation class that runs sub-operation block assigned to it and also stores its parent context (cascade- or transactional-) to control parent operation's flow. Important: suboperations should not be run or touched standalone, but only from inside their corresponding cascade- or transactional- operational contexts only!

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
## Defining and running operations

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

## Each operation yields itself to the block 

All operations yield themselves into the block they declare (like `yield self` is done in Ruby world).

...

## Finish rules.

Non-composite operations: `COOperation` and `COSyncOperation` always must be finished somewhere inside their operation blocks. 

Composite operations: transactional and cascade must not be finished since they automatically become finished when all their sub-operations are done.
 
## Combining operations

Both `COTransactionalOperation` and `COCascadedOperation` have a possibility to inject each other in their bodies: for example, if you inject transactional operation with a number of asynchronous tasks into a cascaded operation, then this transactional operation will be executed when its turn in cascade queue comes. Then, at the moment of its execution, the task will be performed in transactional manner - after that, when all transactional tasks finish their jobs, the flow will return to continue executing tasks in synchronous, ordered cascade queue. And opposite: if you add cascaded operation to the transaction operation - its task of running cascade will be dispatched asynchronously.

## ...

