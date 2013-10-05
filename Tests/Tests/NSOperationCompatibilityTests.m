#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "SACompositeOperations.h"
#import "SACascadeOperation.h"

#import "SATransactionalOperation.h"
#import "SAQueues.h"

@interface NSOperationCompatibilityTests : SenTestCase
@end

static BOOL isExecutingNotificationSent;
static BOOL isFinishedNotificationSent;

@implementation NSOperationCompatibilityTests

- (void)test_SAOperation_basic_KVO_notifications {
    isExecutingNotificationSent = NO;

    SAOperation *operation = [SAOperation new];

    [operation addObserver:self
                forKeyPath:@"isExecuting"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    [operation addObserver:self
                forKeyPath:@"isFinished"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    operation.operation = ^(SAOperation *op){
        STAssertTrue(isExecutingNotificationSent, @"");
        STAssertFalse(isFinishedNotificationSent, @"");

        isExecutingNotificationSent = NO;

        [op finish];

        STAssertTrue(isExecutingNotificationSent, @"");
        STAssertTrue(isFinishedNotificationSent, @"");
    };

    [operation start];

    [operation removeObserver:self forKeyPath:@"isFinished"];
    [operation removeObserver:self forKeyPath:@"isExecuting"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    @synchronized(self) {
        if ([keyPath isEqual:@"isFinished"]) {
            isFinishedNotificationSent = YES;
        }

        if ([keyPath isEqual:@"isExecuting"]) {
            isExecutingNotificationSent = YES;
        }
    }
}

@end
