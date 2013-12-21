//
//  COCompositeOperation_Private.h
//  TestsApp
//
//  Created by Stanislaw Pankevich on 14/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "COCompositeOperation.h"

@interface COCompositeOperation ()

@property (nonatomic) COCompositeOperationConcurrencyType concurrencyType;

@property (nonatomic, strong) NSBlockOperation *zOperation;

@property (nonatomic, strong) NSMutableArray *result;

- (void)_registerDependency:(COOperation *)operation;

- (void)_teardown;

@end
