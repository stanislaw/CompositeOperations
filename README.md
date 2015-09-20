# CompositeOperations 

You might be interested at this project if you use GCD and/or NSOperation but want them to be on a higher level of abstraction: you need to implement the complex flows of operations and for some reasons you are not satisfied with what GCD/NSOperation/NSOperationQueue can do out of a box.

Key features:
 
* Composition of operations, two types: sequential and parallel composition. 
* Multistep asynchronous operations: chaining, parallelizing, synchronizing.
* Mixing (or combining) composite operations into each other.
* CompositeOperations is non-blocking: none of its operations blocks the thread it is executing on.
* Full NSOperation/NSOperationQueue compatibility: all operations are NSOperation subclasses and can be be run inside NSOperationQueue queues.

[![Build Status](https://travis-ci.org/stanislaw/CompositeOperations.png?branch=master)](https://travis-ci.org/stanislaw/CompositeOperations)

## Status 2015.09.20

The project has alpha status. 

## Copyright

Copyright (c) 2014 Stanislaw Pankevich. See LICENSE for details.

