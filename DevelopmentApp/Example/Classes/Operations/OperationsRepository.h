//
//  Operations.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COCompositeOperation;

@protocol COOperation;

@interface OperationsRepository : NSObject

- (COCompositeOperation *)githubUserIssues:(NSString *)user;

- (COCompositeOperation *)issuesForUser:(NSString *)user repositories:(NSArray <NSString *> *)repositories;

- (NSOperation <COOperation> *)repositoriesForUser:(NSString *)user;
- (NSOperation <COOperation> *)issuesForUser:(NSString *)user repository:(NSString *)repository;

@end
