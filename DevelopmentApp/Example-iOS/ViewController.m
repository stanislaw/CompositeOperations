//
//  ViewController.m
//  Example-iOS
//
//  Created by Stanislaw Pankevich on 24/06/15.
//  Copyright (c) 2015 Stanislaw Pankevich. All rights reserved.
//

#import "ViewController.h"

#import <CompositeOperations/CompositeOperations.h>

@interface Operation: COOperation
@end

@implementation Operation
- (void)main {
    NSLog(@"Trivial operation to test things");
}
@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[Operation new] start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
