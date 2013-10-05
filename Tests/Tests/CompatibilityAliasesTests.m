//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"

@interface CompatibilityAliases : SenTestCase
@end

@implementation CompatibilityAliases

- (void)test_CompatibilityAliases {
    STAssertEquals(COCascadeOperation.class, COCascade.class, nil);
    STAssertEquals(COTransactionalOperation.class, COTransaction.class, nil);
}

@end