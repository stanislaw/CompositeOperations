# Changes in CompositeOperations

## Master

----

## Versions 0.5.0-0.5.4

Release date: 2013-12-01

### Complete rewrite of the whole project!

* COTransactionalOperation and COCascadeOperation has been replaced by one COCompositeOperation with two types of concurrency: `COCompositeOperationSerial` and `COCompositeOperationConcurrent`.

CompositeOperation has the only designated initializer:

```objective-c
COCompositeOperation *compositeOperation = [[CompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent]; ...
```

* New methods: `-[COCompositeOperation compositeOperation:]` to run COOperation, and `-[COCompositeOperation compositeOperation:withBlock:]`.

* New experimental method: `- (void)resolveWithOperation:(COOperation *)operation;` to delegate operation's resolution to another operation.

* AFNetworking-inspired `COStateTransitionIsValid` - C function that defines transition map beetween operation states. This map includes error codes for inappropriate transitions.

* All completion handlers now all have `(id result)` argument, all cancellation handlers now have `(COOperation *operation, NSError *error)` or `(COCompositeOperation *compositeOperation, NSError *error)`.

* Number of thread safety related fixes.

* Better `-[COCompositeOperation description]`.

----

## Version 0.4.12

Release date: 2013-11-17

### Removed

* Completely remove COSyncOperation. It will be extracted to a separate project.

## Version 0.4.10

Release date: 2013-10-17

### Fixed

* Fixed issue with Resolution API: calls to COOperation's original completion handlers are now made properly.

## Version 0.4.8

Release date: 2013-10-05

First release after migration. No changes, just completely new naming introduced to the whole project: `SA -> CO`.

----

The project was renamed: `SACompositeOperations -> CompositeOperations` because of the naming conflicts with Apple private frameworks introduced in iOS7 ([SACompositeOperations issue #1](Reason: https://github.com/stanislaw/SACompositeOperations/issues/1)). This inspired author to remove prefix from the name of the project: `CompositeOperations` and change a naming namespace for the whole project: `SA -> CO`.

```
SAOperation -> COOperation
SACascadeOperation -> COCascadeOperation
...
```

----

## Version 0.4.6

Release date: 2013-07-29

### Fixed

* -[SAAbstractCompositeOperation _teardown] to manually break retain cycles beetween composite operations and their suboperations. At last!

## Version 0.4.5

Release date: 2013-07-11

### Added

* `-[SAOperation run:completionHandler:cancellationHandler]` and corresponding `operation(block, completionHandler, cancellationHandler)` helper.

### Changed

* Changes in aggressive lifo: SAOperationQueue now runs `cancel` on operations that are replaced by aggressive newcomers.
* Minor fixes.

## Version 0.4.0

Release date: 2013-06-10

### Added

* `-[SASyncOperation runInQueue:operation:]` and `-[SAOperation runInQueue:operation:]` with proper handling of retain/release for dispatch queue.

### Changed

* Significant simplification and refactoring of composite operations: `SACascadeOperation` and `SATransactionalOperation` now both inherit from `SAAbstractCompositeOperation <SACompositeOperation>` class. `<SACompositeOperation>` protocol defines common routines which both cascade and transactional operation's classes implement. 
* Numerous changes in suspend/resume and cancellation semantics.
* Added `awake` strategy.
* Removed many unneeded (hopefully) synchronization pieces.

## Version 0.3.3

Release date: 2013-05-03

### Changed

* Refactored the internal code for both `SATransactionalOperation` and
`SACascadeOperation`.

## Version 0.3.2

Release date: 2013-04-22

### Added

* SARunOperation() C macros to refactor and shorten duplicate code to run operations and sub-operations.
* Suboperations are enqueued to the same operation queue their parent is in, if it is.

### Changed

* More accurate registration routine for sub-operations of composite operations, both cascade and transactional.
* More solid suspend/resume semantics.
* More careful cancellation semantics for edge cases.
* 'Cancelled' state is now included in `_SAOperationState`

## Version 0.3.1

Release date: 2013-04-14

### Added

* Added `-[SAOperationQueue addOperationWithBlock]`.
* Added OCUnit command line test suite.
* Added support for building on Travis.

### Changed

* SAOperationQueue: when suspended or resumed does not dispatch_suspend/dispatch_resume its queue anymore - what a horrible design solution it was!
* SAOperationQueue does not run enqueued but suspended operations anymore.
* Composite operations: use NSOperation's native `completionBlock` instead of both completionHandler and cancellationHandler.
* Simplified `SACompositeOperationsApp` - it is now a command line tool and runs just `SenSelfTestMain()` without GUI and simulator.
* Replaced global -DOS_OBJECT_USE_OBJC=0 with `#if !OS_OBJECT_USE_OBJC` conditions.

### Removed

* Removed obsolete stuff from SAQueues.

## Version 0.3.0

Release date: 2013-03-29

### Added

* Cancellation blocks for transational and cascade operations are introduced - they are called if at least one of the suboperations is cancelled.
* Suspend/Resume for both SAOperation and SAOperationQueue levels.
* `-[SAOperation debug]` and `-[SAOperationQueue debug]` methods for debugging.
* SAOperationQueue have got `state` property: normal and suspended.
* Introduced resolution methods: they are used resolve operations when there are any problems with their successful completion (see `<SAOperationResolver>` also).

### Changed

* All SAOperation categories merged into main SAOperation class files.
* Significantly reduced a number of similar methods to prevent useless dublication in code and semantics.
* Cancellation semantics: "start" finishes cancelled operation, "reRun" - reinitializes and runs again.
* Improved cancellation semantics for both transactional and cascade operation.
* All `[[... alloc] init]` calls are replaced with just `new` ;)
* Pragma marks have been made more accurate everywhere.
* Namespaced all typedefs with SA.

### Fixed

* Fixed various synchronization issues mainly in SATransactionalOperation.

### Removed

* No more teardown `_finish` or `_teardown` methods - all that stuff was moved to `dealloc` methods.

## Version 0.2.3

### Fixed

* Fixes AGGRESSIVE_LIFO: superseded and thus cancelled operations are not queued anymore.

## Version 0.2.2

### Added

* Added SAOperation+Rerunning category with reRunTimes:eachAfterTimeInterval... method

### Removed

* Completely removed SAAsyncOperation and asyncOperation().

## Version 0.2.1

Release date: 2013-03-12

### Added

* SAOperationQueue now has queueType property. It can be FIFO, LIFO,
AGGRESSIVE_LIFO.

### Fixed

* Calling 'start' on operations without operation blocks: raise exception only for not-cancelled operations.

## Version 0.2.0

Release date: 2013-02-03

### Added

* NSOperation/NSOperationQueue compatibility. SAOperation is a subclass of NSOperation.
* Cancellation semantics

### Changed

* Composite operations use SAOperation for sub-operations.
* SAOperation now is not aware about operation context - it is only done in separate category SAOperation+ContextOperation - composite operations import it by demand.
* Better naming: changed sa prefix to SA in SAQueues.

## Version 0.1.4

Release date: 2013-01-16

### Added

* Compatibility aliases for transaction and cascade operations classes.

## Version 0.1.3

Release date: 2013-01-08

### Fixed

* Fixed observers stuff for isfinished: it is now explicit.

## Version 0.1.2

Release date: 2013-01-08

### Added

* SASyncOperation is a subclass of SAOperation
* SATransactionalOperation: resultForNextOperation => sharedData. Also sharedData property is paired with modifySharedData block method.
* iOS 5.0 support: dispatch_retain, dispatch_release for queues (OS_OBJECT_USE_OBJC=0 for the whole project).

## Version 0.1.1

Release date: 2013-01-06

### Added

* SASyncOperation: do not run CFRunLoopRunInMode if operation is done (for simple blocks possible without any asynchronicity)
* SASyncOperation: important addition to finish run loop from main queue
* Generic SAOperation class for all operations - SA operations move towards the likeness with NSOperation more and more.
* Introduced SAOperationQueue, all non-sync operations can schedule themselves into its subclasses.
* Operations helpers have become much cleaner - they all share the same names now (using overloadable attribute)

### Updated

* Updated directory structure, so the overall project has less files than it had.

### Deprecated

* Deprecated sync composite operations: SASyncCascadeOperation and SASyncTransactionalOperation

## Version 0.1.0

Release date: 2013-01-01

### Changed 

* SASyncOperation improvements

## Version 0.0.15

Release date: 2012-12-22

### Changed

* No more OperationsPool - unit operations retain their contexts.
* "Atomic" operations => "unit" operations transition

## Versions prior to 0.0.15...

Long-long history undocumented...
