
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COCompositeOperation.h"

#import "COQueues.h"

SPEC_BEGIN(SAQueuesSpecs)

describe(@"SAQueues", ^{
    it(@"", ^{
        [[theValue(CODefaultQueue() == concurrentQueue()) should] beYes];

        COSetDefaultQueue(dispatch_get_main_queue());

        [[theValue(CODefaultQueue() == dispatch_get_main_queue()) should] beYes];

        COSetDefaultQueue(nil);

        [[theBlock(^{
            CODefaultQueue();
        }) should] raiseWithName:NSInternalInconsistencyException];
    });
});

SPEC_END
