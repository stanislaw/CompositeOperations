//
//  COOperation_Private.h
//  TestsApp
//
//  Created by Stanislaw Pankevich on 10/23/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "COOperation.h"

typedef NS_ENUM(NSInteger, COOperationState) {
    COOperationCancelledState   = -2,
    COOperationSuspendedState   = -1,
    COOperationReadyState       = 0,
    COOperationExecutingState   = 1,
    COOperationFinishedState    = 2,
};

@interface COOperation ()

@property (nonatomic) COOperationState state;
@property (nonatomic, readonly) NSString *stateKey;

// Context operation
@property (strong) COOperation *contextOperation;

- (void)initPropertiesForRun;
- (void)main;

@end
