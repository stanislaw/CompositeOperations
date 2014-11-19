# CompositeOperations 

**CompositeOperations = NSOperation + NSOperationQueue + block-based API**
 
`CompositeOperations` is an attempt to build a higher-level composite operations framework on top of NSOperation/NSOperationQueue. Its main features are:

* Composite operations - two types of composition: sequential composition - `COSequentialCompositeOperationl`, parallel composition - `COParallelCompositeOperation`. 
* Multistep asynchronous operations: chaining, synchronizing.
* Mixing (or combining) composite operations into each other (See 'Combining Operations').
* CompositeOperations is non-blocking: none of its operations blocks the thread it is executing on.
* NSOperation/NSOperationQueue compatibility: all operations are NSOperation subclasses and can be be run inside NSOperationQueue queues.

You might be interested at this project if you use GCD and/or NSOperation and want them to be on a higher level of abstraction: you need to implement the complex flows of operations and for some reasons you are not satisfied with what NSOperationQueue/NSOperation can do out of a box.

[![Build Status](https://travis-ci.org/stanislaw/CompositeOperations.png?branch=master)](https://travis-ci.org/stanislaw/CompositeOperations)

## Status 2014.11.19

The project has alpha status. 

The author will be very thankful for any feedback: regarding the overall code design or the flow of particular operations.

## Copyright

Copyright (c) 2014 Stanislaw Pankevich. See LICENSE for details.

