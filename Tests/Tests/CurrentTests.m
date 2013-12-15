
#import "TestHelpers.h"

#import "COQueues.h"
#import "CompositeOperations.h"

SPEC_BEGIN(Current_Specs)
describe(@"Current specs", ^{
    beforeEach(^{
        //COSetDefaultQueue(concurrentQueue());
    });

    it(@"", ^{
        COOperation *operation = [COOperation new];
        operation.name = @"Nice op";
        
        NSLog(@"%@", operation);

        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
        compositeOperation.name = @"Nice op";

        NSLog(@"%@", compositeOperation);
    });
});
SPEC_END
