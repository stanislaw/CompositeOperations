# NSOperationQueueController

This is an alpha!

----

A wrapper around NSOperationQueue that provides additional control capabilities:

* FIFO/LIFO orders of enqueuing.
* Limit window: if you add operation to NSOperationQueueController's operation queue, it removes the oldest pending operation if total number of pending operations exceedes given limit.
* NSOperationQueueController has a delegate `<NSOperationQueueControllerDelegate>` which allows you to observe a lifecycle of operations: start, cancellation, finish.



