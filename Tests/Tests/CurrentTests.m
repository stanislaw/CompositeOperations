
#import "TestHelpers.h"

#import "COQueues.h"
#import "CompositeOperations.h"
#import "COCompositeOperation_Private.h"

#import <NSOperationQueueController/NSOperationQueueController.h>

SPEC_BEGIN(Current_Specs)
describe(@"Current specs", ^{
    beforeEach(^{
        COSetDefaultQueue(concurrentQueue());
    });


    it(@"should run composite operation", ^{
    });

});
SPEC_END
