
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COCompositeOperation.h"
#import "COOperation_Private.h"

#import "COCompositeOperation.h"
#import "COQueues.h"

@interface NSOperationCompatibilityTests : SenTestCase
@end

static BOOL isExecutingNotificationSent;
static BOOL isFinishedNotificationSent;

@implementation NSOperationCompatibilityTests

- (void)test_COOperation_basic_KVO_notifications {
    isExecutingNotificationSent = NO;

    COOperation *operation = [COOperation new];

    [operation addObserver:self
                forKeyPath:@"isExecuting"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    [operation addObserver:self
                forKeyPath:@"isFinished"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    operation.operation = ^(COOperation *op){
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
