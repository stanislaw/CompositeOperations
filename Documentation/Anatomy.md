# Anatomy

## COOperation

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

## COCompositeOperation

### COCompositeOperationSerial

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

compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *compositeOperation){
    [compositeOperation operationInQueue:queue1 withBlock:^(COOperation *operation){
        /* 
          ...first job... 
        */

        [operation finish]; // or maybe [operation cancel]...
    }];
    
    [compositeOperation operationInQueue:queue2 withBlock:^(COOperation *operation){
        /* 
          ...second job... 
        */

        [operation finish]; // or maybe [operation cancel]...
    }];
   
    [compositeOperation operationInQueue:queue3 withBlock:^(COOperation *operation){
        /* 
          ...third job... 
        */

        [operation finish]; // or maybe [operation cancel]...
    }]; 

    [compositeOperation operationInQueue:queue4 withBlock:^(COOperation *operation){
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
}, ^(COCompositeOperation *compositeOperation){
    /*
      ...Cancellation handler code... 
      
      ...called immediatedly if at least one suboperation was cancelled
     
      Here decide what to do with *the whole composite operation* then
    */
});
```

The following will run serial composite operation - it will schedule 3 asynchronous suboperations (All 3 operations will be run in a queue set by COSetDefaultQueue()).

The order of execution:

1. The outer composite operation block - schedules suboperations:
2. First suboperation
3. Second suboperation
4. Third suboperation
 
```objective-c
COSetDefaultQueue(someQueue());

compositeOperation(^(COCompositeOperation *compositeOperation) {
    [compositeOperation operationWithBlock:^(COOperation *o) {
        /*
          The first suboperation to run:
          ...Do stuff...
        */

        [o finish];
    }];

    [compositeOperation operationWithBlock:^(COOperation *o) {
        /*
          The second suboperation to run:
          ...Do stuff...
        */

        [o finish];
    }];

    [compositeOperation operationWithBlock:^(COOperation *o) {
        /* 
          The third suboperation to run:
          ...Do stuff...
        */

        [o finish];
    }];
    // At this point - after the outer block have just run - all operations are scheduled to be run in CODefaultQueue()
}, nil, nil);
```
### COCompositeOperationConcurrent

The following example will run composite concurrent operation - it will schedule 3 asynchronous suboperations (All 3 operations will be run in a queue set by COSetDefaultQueue()).

The order of execution:

1. The outer composite operation block - schedules suboperations.
2. All 3 suboperations will be run in an order dictated by the CO default queue (serial or concurrent - both are fine)
3. Completion handler if all suboperations finished or cancellation handler if at least one suboperation was cancelled

```objective-c
COSetDefaultQueue(concurrentQueue());

compositeOperation(^(COCompositeOperation *compositeOperation) {
    [compositeOperation operation:^(COOperation *operation) {
        /* 
          I'am the first suboperation in order but since I am inside a concurrent operation (not serial!) 
          it is not guaranteed that I actually will be the first to be run 
          since CODefaultQueue() is concurrent...

          ...Do stuff...
        */

        [operation finish]; // or maybe [operation cancel]
    }];
    [compositeOperation operation:^(COOperation *operation) {
        /*
          ...Do stuff...
        */

        [operation finish]; // or maybe [operation cancel]
    }];
    [compositeOperation operation:^(COOperation *operation) {
        /*
          ...Do stuff...
        */

        [operation finish]; // or maybe [operation cancel]
    }];
}, ^{
    /*
      ...Completion handler code...
    */

}, ^(COCompositeOperation *compositeOperation){
    /*
      ...Cancellation handler code...
      ...called immediatedly if at least one of suboperations is cancelled.
      ...here maybe resolve composite operation somehow: rerun, rerun after, or cancel... see <COOperationResolver>
    */
});

```



