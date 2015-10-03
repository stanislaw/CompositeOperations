//
//  GithubRepositoryIssuesFetchOperation.m
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import "GithubRepositoryIssuesFetchOperation.h"

@interface GithubRepositoryIssuesFetchOperation ()
@property (readonly, nonatomic) NSString *user;
@property (readonly, nonatomic) NSString *repository;
@end

@implementation GithubRepositoryIssuesFetchOperation

- (id)initWithUser:(NSString *)user repository:(NSString *)repository {
    NSParameterAssert(user);
    NSParameterAssert(repository);

    self = [super init];

    _repository = repository;
    _user       = user;

    return self;
}

- (void)main {
    NSString *repositoryIssuesPath = [NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/issues?state=all&page=1&per_page=10&sort=updated", self.user, self.repository];

    NSURL *repositoryIssuesURL = [NSURL URLWithString:[repositoryIssuesPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    NSURLRequest *repositoriesRequest = [NSURLRequest requestWithURL:repositoryIssuesURL];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:repositoriesRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self rejectWithError:error];
            return;
        }

        NSError *parsingError = nil;
        id issues = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parsingError];

        if (issues == nil) {
            [self rejectWithError:parsingError];
            return;
        }

        // Github can return 200 with error message in it.
        if ([issues isKindOfClass:[NSArray class]] == NO) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:issues];

            [self rejectWithError:error];
            return;
        }

        NSArray *issueNames = [issues valueForKey:@"title"];
        [self finishWithResult:issueNames];
    }];
    
    [task resume];
}

@end
