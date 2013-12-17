#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COCompositeOperation_Private.h"

#import <NSOperationQueueController/NSOperationQueueController.h>

SPEC_BEGIN(NSOperationQueueControllerIntegrationSpecs)

describe(@"NSOperationQueueController, COCompositeOperationSerial", ^{
    specify(^{
        NSOperationQueue *operationQueue = [NSOperationQueue new];
        NSOperationQueueController *controller = [[NSOperationQueueController alloc] initWithOperationQueue:operationQueue];

        __block BOOL isFinished = NO;
        NSMutableArray *registy = [NSMutableArray array];

        compositeOperation(COCompositeOperationSerial, controller, ^(COCompositeOperation *compositeOperation) {
            [compositeOperation operationWithBlock:^(COOperation *cao) {
                NSAssert(registy.count == 0, nil);

                [registy addObject:@(1)];

                [cao finish];
            }];

            [compositeOperation operationWithBlock:^(COOperation *cao) {
                NSAssert(registy.count == 1, nil);
                
                [registy addObject:@(2)];

                [cao finish];
            }];

            [compositeOperation operationWithBlock:^(COOperation *cao) {
                NSAssert(registy.count == 2, nil);

                [registy addObject:@(3)];

                [cao finish];
                isFinished = YES;
            }];
        }, nil, nil);

        while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

        BOOL registryIsCorrect = [registy isEqual:@[ @(1), @(2), @(3) ]];
        [[theValue(registryIsCorrect) should] beYes];

    });
});

describe(@"NSOperationQueueController, COCompositeOperationConcurrent", ^{
    for (int i = 0; i < 1; i++) {
        it(@"should run composite concurrent operation", ^{
            __block BOOL isFinished = NO;

            NSMutableArray *registy = [NSMutableArray array];

            NSOperationQueue *operationQueue = [NSOperationQueue new];
            NSOperationQueueController *controller = [[NSOperationQueueController alloc] initWithOperationQueue:operationQueue];

            __block COCompositeOperation *__compositeOperation;

            compositeOperation(COCompositeOperationConcurrent, controller, ^(COCompositeOperation *compositeOperation) {

                compositeOperation.name = [@(i) stringValue];
                __compositeOperation = compositeOperation;

                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"CompositeOp %@, %@", compositeOperation, controller);
                });

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    operation.name = [NSString stringWithFormat:@"%@.1", @(i)];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [registy addObject:@(1)];
                        [operation finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    operation.name = [NSString stringWithFormat:@"%@.2", @(i)];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [registy addObject:@(2)];
                        [operation finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    operation.name = [NSString stringWithFormat:@"%@.3", @(i)];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"op %@, %@", compositeOperation, controller);

                        [registy addObject:@(3)];
                        [operation finish];
                    });

                }];
            }, ^(NSArray *result){
                isFinished = YES;
            }, ^(COCompositeOperation *compositeOperation, NSError *error){
                raiseShouldNotReachHere();
            });

            int count = 0;
            while (isFinished == NO) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                if (++count % 10 == 0) {
                    NSLog(@"%@, %d, %@, %@", __compositeOperation, __compositeOperation.zOperation.isFinished, __compositeOperation.zOperation.dependencies, controller);
                }
            }

            BOOL registryIsCorrect = (registy.count == 3);
            [[theValue(registryIsCorrect) should] beYes];
        });
    }
});

describe(@"NSOperationQueueController, -[operation reject]", ^{
    it(@"", ^{
        __block BOOL blockFlag = NO;

        NSOperationQueue *operationQueue = [NSOperationQueue new];
        NSOperationQueueController *controller = [[NSOperationQueueController alloc] initWithOperationQueue:operationQueue];

        __block COOperation *op;
        operation(controller, ^(COOperation *operation) {
            op = operation;

            [operation reject];

        }, ^(id result){
            raiseShouldNotReachHere();
        }, ^(COOperation *operation, NSError *error){
            NSAssert(operation, nil);
            NSAssert(operation.isCancelled, nil);

            [[theValue(operation.isCancelled) should] beYes];

            blockFlag = YES;
        });

        while(blockFlag == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

        [[theValue(op.isCancelled) should] beYes];
    });
});


SPEC_END

//


