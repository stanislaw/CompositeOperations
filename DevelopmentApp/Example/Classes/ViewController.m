//
//  ViewController.m
//  Example
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import "ViewController.h"

#import "OperationsRepository.h"

#import "CompositeOperations.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *githubUser = @"facebook";

    COCompositeOperation *githubUserIssuesOperation = [[OperationsRepository new] githubUserIssues:githubUser];

    githubUserIssuesOperation.completion = ^(NSArray *results, NSArray *errors) {
        if (results) {
            id finalResult = results.lastObject;

            NSLog(@"Success: %@", finalResult);
        } else {
            NSLog(@"Error: %@", errors);
        }
    };

    [[NSOperationQueue mainQueue] addOperation:githubUserIssuesOperation];
}

@end
