//COOperationQueue *opQueue = [COOperationQueue new];
//opQueue.queue = concurrentQueue();
//
//__block int count = 0;
//__block BOOL isFinished = NO;
//
//compositeOperation(COCompositeOperationSerial, opQueue, ^(COCompositeOperation *compositeOperation) {
//    [compositeOperation operationWithBlock:^(COOperation *cao) {
//        count = count + 1;
//
//        STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");
//
//        [cao finish];
//    }];
//
//    [compositeOperation operationWithBlock:^(COOperation *cao) {
//        count = count + 1;
//
//        STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");
//
//        [cao finish];
//    }];
//
//    [compositeOperation operationWithBlock:^(COOperation *cao) {
//        count = count + 1;
//
//        STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");
//
//        [cao finish];
//        isFinished = YES;
//    }];
//}, nil, nil);
//
//while (!isFinished) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
//
//STAssertEquals(count, 3, @"Expected count to be equal 3");
//
//- (void)test_COCompositeOperationConcurrent_in_operation_queue {
//    __block BOOL isFinished = NO;
//    NSMutableArray *countArr = [NSMutableArray array];
//
//    COOperationQueue *opQueue = [COOperationQueue new];
//    opQueue.queue = createQueue();
//
//    compositeOperation(COCompositeOperationConcurrent, opQueue, ^(COCompositeOperation *to) {
//        [to operationWithBlock:^(COOperation *tao) {
//
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//
//            [tao finish];
//        }];
//
//        [to operationWithBlock:^(COOperation *tao) {
//
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//
//            [tao finish];
//        }];
//
//        [to operationWithBlock:^(COOperation *tao) {
//
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//
//            [tao finish];
//        }];
//    }, ^(NSArray *result){
//        isFinished = YES;
//    }, ^(COCompositeOperation *to, NSError *error){
//        raiseShouldNotReachHere();
//    });
//
//    while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
//        
//        STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
//        }

//- (void)test_run_completionHandler_cancellationHandler {
//    __block BOOL blockFlag = NO;
//
//    COOperationQueue *queue = [COOperationQueue new];
//    queue.queue = serialQueue();
//
//    __block COOperation *op;
//
//    operation(queue, ^(COOperation *operation) {
//        op = operation;
//        [operation cancel];
//    }, ^(id result){
//        raiseShouldNotReachHere();
//    }, ^(COOperation *operation, NSError *error){
//        STAssertTrue(op.isCancelled, nil);
//
//        blockFlag = YES;
//    });
//
//    while(blockFlag == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
//        }

