//
//  GithubUserRepositoriesFetchOperation.m
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import "GithubUserRepositoriesFetchOperation.h"

@interface GithubUserRepositoriesFetchOperation ()
@property (readonly, nonatomic) NSString *user;
@end

@implementation GithubUserRepositoriesFetchOperation

- (id)initWithUser:(NSString *)user {
    NSParameterAssert(user);

    self = [super init];

    _user = user;

    return self;
}

- (void)main {
    NSString *repositoriesPath = [NSString stringWithFormat:@"https://api.github.com/users/%@/repos?page=1&per_page=5", self.user];

    NSURL *repositoriesURL = [NSURL URLWithString:[repositoriesPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    NSURLRequest *repositoriesRequest = [NSURLRequest requestWithURL:repositoriesURL];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:repositoriesRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self rejectWithError:error];
            return;
        }

        NSError *parsingError = nil;
        id repositories = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parsingError];

        if (repositories == nil) {
            [self rejectWithError:parsingError];
            return;
        }

        // Github can return 200 with error message in it.
        if ([repositories isKindOfClass:[NSArray class]] == NO) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:repositories];

            [self rejectWithError:error];
            return;
        }

        NSArray *repositoryNames = [repositories valueForKey:@"name"];
        [self finishWithResult:repositoryNames];
    }];
    
    [task resume];
}

@end
