//
//  AppDelegate.m
//  Example-OSX
//
//  Created by Stanislaw Pankevich on 24/06/15.
//  Copyright (c) 2015 Stanislaw Pankevich. All rights reserved.
//

#import "AppDelegate.h"

#import <CompositeOperations/CompositeOperations.h>

@interface Operation: COOperation
@end

@implementation Operation
- (void)main {
    NSLog(@"Trivial operation to test integration");

    [self finish];
}
@end

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    Operation *operation = [Operation new];

    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithOperations:@[ operation ] runInParallel:NO];

    __weak COCompositeOperation *weakCompositeOperation = compositeOperation;

    compositeOperation.completionBlock = ^{
        NSLog(@"%@", weakCompositeOperation);
    };

    [[NSOperationQueue mainQueue] addOperation:compositeOperation];
}

@end
