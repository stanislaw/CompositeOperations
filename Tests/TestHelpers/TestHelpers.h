
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>

#import "Assertions.h"
#import "TestOperations.h"

static inline void waitUsingSemaphore(dispatch_semaphore_t semaphore) {
    static const NSTimeInterval WaitInterval = 1;

    NSDate *startingDate = [NSDate date];

    while ([[NSDate date] timeIntervalSinceDate:startingDate] < WaitInterval && dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
    }
}

#define NSSTRING_CONSTANT(name) NSString *const name = @ #name
