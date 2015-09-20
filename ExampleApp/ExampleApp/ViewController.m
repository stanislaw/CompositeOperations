//
//  ViewController.m
//  ExampleApp
//
//  Created by Stanislaw Pankevich on 20/09/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import "ViewController.h"

#import <CompositeOperations/CompositeOperations.h>

@interface Operation: COOperation
@end

@implementation Operation
- (void)main {
    NSLog(@"Trivial operation to test integration");

    [self finish];
}
@end

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    NSLog(@"CompositeOperations: %f %s", CompositeOperationsVersionNumber, CompositeOperationsVersionString);

    Operation *operation = [Operation new];

    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithOperations:@[ operation ] runInParallel:NO];

    __weak COCompositeOperation *weakCompositeOperation = compositeOperation;

    compositeOperation.completionBlock = ^{
        NSLog(@"%@", weakCompositeOperation);
    };

    [[NSOperationQueue mainQueue] addOperation:compositeOperation];
}

@end
