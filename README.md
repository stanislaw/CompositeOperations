# CompositeOperations 

CompositeOperations is implementation of Futures/Promises pattern on top of NSOperation/NSOperationQueue infrastructure.

Key features:
 
* Composition of operations, two types: sequential composition - `COSequentialOperation`, parallel composition - `COParallelOperation`. 
* Multistep asynchronous operations: chaining, parallelizing, synchronizing.
* Mixing (or combining) composite operations into each other.
* CompositeOperations is non-blocking: none of its operations blocks the thread it is executing on.
* Full NSOperation/NSOperationQueue compatibility: all operations are NSOperation subclasses and can be be run inside NSOperationQueue queues.

You might be interested at this project if you use GCD and/or NSOperation and want them to be on a bit higher level of abstraction: you need to implement the complex flows of operations and for some reasons you are not satisfied with what NSOperation/NSOperationQueue can do out of a box.

[![Build Status](https://travis-ci.org/stanislaw/CompositeOperations.png?branch=master)](https://travis-ci.org/stanislaw/CompositeOperations)

## Status 2014.11.19

The project has alpha status. 

The author will be very thankful for any feedback: regarding the overall code design or the flow of particular operations.

## Copyright

Copyright (c) 2014 Stanislaw Pankevich. See LICENSE for details.

