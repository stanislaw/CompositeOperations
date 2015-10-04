//
//  GithubUserActivityOperationSequence.m
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import "GithubUserIssuesOperationSequence.h"

#import "OperationsRepository.h"

#import "GithubUserRepositoriesFetchOperation.h"

@interface GithubUserIssuesOperationSequence ()
@property (readonly, nonatomic) NSString *user;
@end

@implementation GithubUserIssuesOperationSequence

- (id)initWithGithubUser:(NSString *)user {
    self = [super init];

    _user = user;

    return self;
}

- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation<COOperation> *)previousOperationOrNil {
    // Nothing behind - it's a first operation
    if (previousOperationOrNil == nil) {
        return [[OperationsRepository new] repositoriesForUser:self.user];
    }

    // Second operation follows the first
    if ([previousOperationOrNil isKindOfClass:[GithubUserRepositoriesFetchOperation class]] &&
        previousOperationOrNil.result) {
        NSArray *repositories = previousOperationOrNil.result;

        return [[OperationsRepository new] issuesForUser:self.user repositories:repositories];
    }

    // Returning nil tells composite operation that we are done
    return nil;
}

@end
