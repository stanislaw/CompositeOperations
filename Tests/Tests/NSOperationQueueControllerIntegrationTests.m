#import "TestHelpers.h"

#import "CompositeOperations.h"
#import <NSOperationQueueController/NSOperationQueueController.h>

SPEC_BEGIN(NSOperationQueueControllerIntegrationSpecs)

describe(@"NSOperationQueueController, COCompositeOperationSerial", ^{
    it(@"", ^{
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
    it(@"sss", ^{
        __block BOOL isFinished = NO;

        NSMutableArray *registy = [NSMutableArray array];

        NSOperationQueue *operationQueue = [NSOperationQueue new];
        NSOperationQueueController *controller = [[NSOperationQueueController alloc] initWithOperationQueue:operationQueue];

        compositeOperation(COCompositeOperationConcurrent, controller, ^(COCompositeOperation *to) {
            [to operationWithBlock:^(COOperation *operation) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [registy addObject:@(1)];
                    [operation finish];
                });
            }];

            [to operationWithBlock:^(COOperation *operation) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [registy addObject:@(2)];
                    [operation finish];
                });
            }];

            [to operationWithBlock:^(COOperation *operation) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [registy addObject:@(3)];
                    [operation finish];
                });

            }];
        }, ^(NSArray *result){
            isFinished = YES;
        }, ^(COCompositeOperation *to, NSError *error){
            raiseShouldNotReachHere();
        });

        while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

        BOOL registryIsCorrect = registy.count == 3;
        [[theValue(registryIsCorrect) should] beYes];
    });
});

describe(@"NSOperationQueueController, -[operation cancel]", ^{
    it(@"", ^{
        __block BOOL blockFlag = NO;

        NSOperationQueue *operationQueue = [NSOperationQueue new];
        NSOperationQueueController *controller = [[NSOperationQueueController alloc] initWithOperationQueue:operationQueue];

        __block COOperation *op;
        operation(controller, ^(COOperation *operation) {
            op = operation;

            [operation cancel];

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


