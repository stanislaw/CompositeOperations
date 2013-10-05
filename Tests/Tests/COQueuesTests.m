//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCascadeOperation.h"
#import "COTransactionalOperation.h"

#import "COQueues.h"

@interface SAQueuesTests : SenTestCase
@end

@implementation SAQueuesTests

- (void) test_defaultQueue_and_setDefaultQueue {
    STAssertTrue((SADefaultQueue() == concurrentQueue()), @"Expected default queue to be nil");

    COSetDefaultQueue(dispatch_get_main_queue());

    STAssertEquals(SADefaultQueue(), dispatch_get_main_queue(), @"Expected defaultQueue() to be equal to main_queue()");

    COSetDefaultQueue(nil);

    STAssertThrowsSpecific(SADefaultQueue(), NSException, @"Expected default queue to be nil after setting to nil by setDefaultQueue");
}


@end
