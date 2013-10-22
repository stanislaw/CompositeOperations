//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import "TestHelpers.h"

#import "COSyncOperation.h"

SPEC_BEGIN(COSyncOperation_Specs)

describe(@"COSyncOperation", ^{
    describe(@"-run:", ^{
        it(@"should run operation", ^{
            __block BOOL soOver = NO;

            COSyncOperation *syncOperation = [COSyncOperation new];

            [syncOperation run:^(COSyncOperation *so) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_async(createQueue(), ^{
                        soOver = YES;

                        [so finish];
                    });
                });
            }];
            
            [[theValue(soOver) should] beYes];
        });
    });

    describe(@"-runInQueue:operation:", ^{
        it(@"should ...", ^{
            dispatch_queue_t queue = dispatch_queue_create("some queue", NULL);
            __block BOOL soOver = NO;

            COSyncOperation *syncOperation = [COSyncOperation new];

            [syncOperation runInQueue:queue operation:^(COSyncOperation *so) {
                soOver = YES;
                [so finish];
            }];
            
            [[theValue(soOver) should] beYes];
        });

        describe(@"Rough integration", ^{
            it(@"", ^{
                dispatch_queue_t queue = dispatch_queue_create("some queue", NULL);

                for (int i = 0; i < 10; i++) {
                    __block BOOL soOver = NO;

                    COSyncOperation *syncOperation = [COSyncOperation new];

                    [[theValue(syncOperation.isFinished) should] beNo];

                    [syncOperation runInQueue:queue operation:^(COSyncOperation *so) {
                        [[theValue(syncOperation.isFinished) should] beNo];

                        soOver = YES;
                        [so finish];
                    }];
                    
                    [[theValue(syncOperation.isFinished) should] beYes];
                    [[theValue(soOver) should] beYes];
                }

            });
        });
    });

    describe(@"Rerunning sync operation", ^{
        describe(@"-reRun", ^{
            it(@"should ...", ^{
                __block int count = 0;

                COSyncOperation *syncOperation = [COSyncOperation new];

                [syncOperation run:^(COSyncOperation *so) {
                    count = count + 1;

                    if (count == 1) {
                        [so reRun];
                    } else
                        [so finish];
                }];
                
                [[theValue(count) should] equal:@(2)];
            });
        });
    });

});

SPEC_END
