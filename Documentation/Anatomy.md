# Anatomy

## Four operations

### COOperation

The `COOperation` is just a block of code wrapped into an NSOperation subclass with additional capabilities: since COOperation yields itself to the block to be executed (see `Each operation yields itself to the block`), it is possible to get more control of operation's execution flow: it is possible to cancel, suspend/resume, rerun (and some more options) operation from inside its own operation body.

The most simple example: use `operation` (C-function wrapper for COOperation, part of CompositeOperations DSL) to create and immediatedly run an operation block:

```objective-c
operation(concurrentQueue(), ^(COOperation *operation) {
    /*
      ...Do some possibly multiqueued and multiblocked stuff...

      ...And then somewhere at the point you consider operation is done, finish it with the -finish:
    */

    [operation finish];
});
```

### COSyncOperation

``` objective-c
syncOperation(^(COSyncOperation *so) {
    doSomeThingMultiQueuedAndAsynchronous(^{
        /*
          ...Do stuff...
        */

        // and then call "finish" so original flow can continue:
        [so finish];
    });
}); // <- The original flow will be stopped at this point waiting when 'so' operation will finish itself

```

### COTransactionalOperation

The following example will run transactional operation - it will schedule 3 asynchronous suboperations (All 3 operations will be run in a queue set by COSetDefaultQueue()).

The order of execution:

1. The outer transactional operation block - schedules suboperations.
2. All 3 suboperations will be run in an order dictated by the CO default queue (serial or concurrent - both are fine)
3. Completion handler if all suboperations finished or cancellation handler if at least one suboperation was cancelled

```objective-c
COSetDefaultQueue(concurrentQueue());

transactionalOperation(^(COTransactionalOperation *transaction) {
    [transaction operation:^(COOperation *operation) {
        /* 
          I'am the first suboperation in order but since I am inside a transaction (not a cascade!) 
          it is not guaranteed that I actually will be the first to be run 
          since CODefaultQueue() is concurrent...

          ...Do stuff...
        */

        [operation finish]; // or maybe [operation cancel]
    }];
    [transaction operation:^(COOperation *operation) {
        /*
          ...Do stuff...
        */

        [operation finish]; // or maybe [operation cancel]
    }];
    [transaction operation:^(COOperation *operation) {
        /*
          ...Do stuff...
        */

        [operation finish]; // or maybe [operation cancel]
    }];
}, ^{
    /*
      ...Completion handler code...
    */

}, ^(COTransactionalOperation *transaction){
    /*
      ...Cancellation handler code...
      ...called immediatedly if at least one of suboperations is cancelled.
      ...here maybe resolve transaction somehow: rerun, rerun after, or cancel... see <COOperationResolver>
    */
});

```

### COCascadedOperation

```objective-c
dispatch_async(queue1, ^{
    /* 
      ...first job... 
    */

    dispatch_async(queue2, ^{
        /* 
          ...second job... 
        */
        
        dispatch_async(queue3, ^{
            /* 
              ...third job... 
            */
            
            dispatch_async(queue4, ^{ 
                /*
                  ...fourth job... 
                */ 
            });
        });
    });    
});

// ...turns into 

cascadeOperation(^(COCascadeOperation *cascade){
    [cascade operationInQueue:queue1 operation:^(COOperation *operation){
        /* 
          ...first job... 
        */

        [operation finish]; // or maybe [operation cancel]...
    }];
    
    [cascade operationInQueue:queue2 operation:^(COOperation *operation){
        /* 
          ...second job... 
        */

        [operation finish]; // or maybe [operation cancel]...
    }];
   
    [cascade operationInQueue:queue3 operation:^(COOperation *operation){
        /* 
          ...third job... 
        */

        [operation finish]; // or maybe [operation cancel]...
    }]; 

    [cascade operationInQueue:queue4 operation:^(COOperation *operation){
        /* 
          ...fourth job... 
        */

        [operation finish];
    }]; 
}, ^{
    /*
      ...Completion handler code... 
      
      ...called if all three suboperations were finished
    */
}, ^(COCascadeOperation *cascade){
    /*
      ...Cancellation handler code... 
      
      ...called immediatedly if at least one suboperation was cancelled
     
      Here decide what to do with *cascade* then
    */
});
```

The following will run cascade operation - it will schedule 3 asynchronous suboperations (All 3 operations will be run in a queue set by COSetDefaultQueue()).

The order of execution:

1. The outer cascade operation block - schedules suboperations:
2. First suboperation
3. Second suboperation
4. Third suboperation
 
```objective-c
COSetDefaultQueue(someQueue());

cascadeOperation(^(COCascadeOperation *co) {
    [co operation:^(COOperation *o) {
        /*
          The first suboperation to run:
          ...Do stuff...
        */

        [o finish];
    }];

    [co operation:^(COOperation *o) {
        /*
          The second suboperation to run:
          ...Do stuff...
        */

        [o finish];
    }];

    [co operation:^(COOperation *o) {
        /* 
          The third suboperation to run:
          ...Do stuff...
        */

        [o finish];
    }];
    // At this point - after the outer block have just run - all operations are scheduled to be run in CODefaultQueue()
}, nil, nil);
```


