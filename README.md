# CompositeOperations 

**CompositeOperations = NSOperation/NSOperationQueue + block-based DSL**
 
`CompositeOperations` is the attempt to build a higher-level composite operations framework on top of GCD. Its main features are:

* Composite operations: sequential composition (`COCascadeOperation`), concurrent composition (`COTransactionalOperation`). 
* Multistep asynchronous operations: chaining and synchronizing.
* Mixing (or combining) composite operations into each other (See 'Combining Operations').
* NSOperation/NSOperationQueue compatibility: all operations are NSOperation subclasses.
* Nice block-based DSL.
* COOperationQueue: analogue of NSOperation designed to work with composite operations. FIFO, LIFO, "agressive LIFO" orders support.
* Experimental API: operation resolution API - special COOperationResolver class to decide what to do with problematic operations that need resolution.

You might be interested at this project if you use GCD and/or NSOperation, but want it to be on a higher level of abstraction: you need to implement the complex flows of operations and for some reasons you are not satisfied with what NSOperationQueue/NSOperation can do out of a box.

[![Build Status](https://travis-ci.org/stanislaw/CompositeOperations.png?branch=master)](https://travis-ci.org/stanislaw/CompositeOperations)

## Status 2013.10.26

The project still has alpha status. 

The author will be very thankful for any feedback: regarding the overall code design or the flow of particular operations.

Documentation is [coming](https://github.com/stanislaw/CompositeOperations/blob/master/Documentation/Index.md).

## Copyright

Copyright (c) 2013 Stanislaw Pankevich. See LICENSE for details.

