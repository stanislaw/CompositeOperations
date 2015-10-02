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

    if ([previousOperationOrNil isKindOfClass:[GithubUserRepositoriesFetchOperation class]]) {
        NSArray *repositories = previousOperationOrNil.result;

        NSMutableArray *issuesForRepositoriesOperations = [NSMutableArray new];

        for (NSString *repository in repositories) {
            NSOperation *repositoryIssues = [[OperationsRepository new] issuesForUser:self.user repository:repository];

            [issuesForRepositoriesOperations addObject:repositoryIssues];
        }

        return [[COCompositeOperation alloc] initWithOperations:issuesForRepositoriesOperations runInParallel:YES];
    }

    return nil;
}

@end
