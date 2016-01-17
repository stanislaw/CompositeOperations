
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>

#import "Assertions.h"
#import "TestOperations.h"

static inline void waitForCompletion(void (^completion)(void (^)(void))) {
    static const NSTimeInterval WaitInterval = 1;

    NSDate *startingDate = [NSDate date];

    __block BOOL flag = NO;

    void (^done)(void) = ^{
        flag = YES;
    };

    completion(done);

    while ([[NSDate date] timeIntervalSinceDate:startingDate] < WaitInterval && flag == NO) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
    }
}
