# Documentation

* [Anatomy (in progress)](Anatomy.md)

## Introduction

The idea of this code comes from the logic of one iPhone app which involved a large number of complex (or "composite") operations, i.e.  operations consisting of multiple sub-operations: sometimes these operations should have to be run strictly one after another, so that particular operation depends on the results of preceding operations (serial order) and sometimes it is needed to run two or three operations in a random order but having a completion handler called when all of these operations are done (concurrent order).

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

## CompositeOperations API

...

## Alternative tools

Any library implementing __Futures and promises__ pattern (http://en.wikipedia.org/wiki/Futures_and_promises can be a good alternative to this project. Author thinks it is just a matter of style and personal preferences.

* [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)

> A framework for composing and transforming streams of values

* [couchdeveloper/RXPromise](https://github.com/couchdeveloper/RXPromise)

> An Objective-C Class which implements the Promises/A+ specification.

