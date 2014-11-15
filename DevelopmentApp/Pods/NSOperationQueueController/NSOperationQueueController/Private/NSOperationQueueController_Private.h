//
//  NSOperationQueueController_Private.h
//  NSOQCDevelopmentApp
//
//  Created by Stanislaw Pankevich on 15/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "NSOperationQueueController.h"

static inline NSUInteger numberOfPendingOperationsToRun(NSUInteger source, NSUInteger destination, NSUInteger limit) {
    NSUInteger safeLimit = limit == NSOperationQueueDefaultMaxConcurrentOperationCount ? NSUIntegerMax : limit;

    return MIN(limit, MIN(source, MAX(0, safeLimit - destination)));
}

@interface NSOperationQueueController ()

@property (strong, nonatomic) NSOperationQueue* operationQueue;

@property (strong) NSMutableArray *pendingOperations;
@property (strong) NSMutableArray *enqueuedOperations;

- (void)_runNextOperationIfExists;
- (NSUInteger)numberOfPendingOperationsToRun;

@end
