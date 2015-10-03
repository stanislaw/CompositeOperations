//
//  Operations.m
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import "OperationsRepository.h"

#import "GithubUserRepositoriesFetchOperation.h"
#import "GithubRepositoryIssuesFetchOperation.h"

#import "GithubUserIssuesOperationSequence.h"

#import "CompositeOperations.h"

@interface OperationsRepository ()
@end

@implementation OperationsRepository

#pragma mark - Composite

- (COCompositeOperation *)githubUserIssues:(NSString *)user {
    id <COSequence> sequence = [[GithubUserIssuesOperationSequence alloc] initWithGithubUser:user];

    return [[COCompositeOperation alloc] initWithSequence:sequence];
}

- (COCompositeOperation *)issuesForUser:(NSString *)user repositories:(NSArray <NSString *> *)repositories {
    NSMutableArray *issuesForRepositoriesOperations = [NSMutableArray new];

    for (NSString *repository in repositories) {
        NSOperation *repositoryIssues = [self issuesForUser:user repository:repository];

        [issuesForRepositoriesOperations addObject:repositoryIssues];
    }

    return [[COCompositeOperation alloc] initWithOperations:issuesForRepositoriesOperations runInParallel:YES];
}

#pragma mark - Simple

- (NSOperation <COOperation> *)repositoriesForUser:(NSString *)user {
    return [[GithubUserRepositoriesFetchOperation alloc] initWithUser:user];
}

- (NSOperation <COOperation> *)issuesForUser:(NSString *)user repository:(NSString *)repository {
    return [[GithubRepositoryIssuesFetchOperation alloc] initWithUser:user repository:repository];
}

@end
