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

Composite Operations has two types of operations: simple - `COSimpleOperation` and composite - `COCompositeOperation` which both conform to `<COOperation>` protocol (see [UML diagram](https://github.com/stanislaw/CompositeOperations/blob/master/CompositeOperations-Diagram.svg)).

TODO

## Examples

See [Documentation/Examples](Documentation/Examples.md).

Also see DevelopmentApp project and Example target in it.

## Copyright

Copyright (c) 2014 Stanislaw Pankevich. See LICENSE for details.

