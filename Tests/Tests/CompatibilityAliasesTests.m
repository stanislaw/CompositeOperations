//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "SACompositeOperations.h"

@interface CompatibilityAliases : SenTestCase
@end

@implementation CompatibilityAliases

- (void)test_CompatibilityAliases {
    STAssertEquals(SACascadeOperation.class, SACascade.class, nil);
    STAssertEquals(SATransactionalOperation.class, SATransaction.class, nil);
}

@end