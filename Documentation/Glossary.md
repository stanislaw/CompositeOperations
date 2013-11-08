## What composite means here? (Glossary)

The following words used here have their specific meaning in the context of this project: __cascade__, __transactional__, __composite__. 
 
__Transactional__ Transactional operation schedules the execution of a number of async sub-operations and runs a completion handler when they all finish their jobs. The key feature of transactional operation is that it doesn't care about the order in which its sub-operations run and finish themselves: completion handler is called at the moment when all of them will be done altoghether - after completion handler is called transactional operation finishes itself. 
 
`COTransactionalOperation` due to its async- nature does not block its original queue/thread (it just schedules sub-operations blocks there) but provides a completion handler instead, which is called when all sub-operations are over.

__Cascade__ Cascade of operations: execute a sub-set of operations strictly one after another. Very useful for the cases when each of the operations is based on the results of operations that had been completed before.

`COCascadeOperation` has async nature: in original queue/thread, in which it is run, it just schedules async sub-operations and runs the first sub-operation (leaving the original thread if the first sub-operation is scheduled to be run in some other queue). When the first sub-operation is over, it summons the second operation, second operation runs, finishes, summons the third and so on.  

__Composite__ In the context of this project "Composite operation" means "complex operation": transactional operation, cascaded operation, or their combination, "mixtum compositum" (See "Combining operations").

__Suboperations__ Both cascade and transactional operations schedule and run suboperations declared inside their bodies. Each suboperation block generates COOperation class that runs sub-operation block assigned to it and also stores its parent context (cascade- or transactional-) to control parent operation's flow. Important: suboperations should not be run or touched standalone, but only from inside their corresponding cascade- or transactional- operational contexts only!

