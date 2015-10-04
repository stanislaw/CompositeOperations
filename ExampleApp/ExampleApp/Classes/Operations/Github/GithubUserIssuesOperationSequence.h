//
//  GithubUserActivityOperationSequence.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CompositeOperations/COSequence.h>

@interface GithubUserIssuesOperationSequence : NSObject <COSequence>

- (id)initWithGithubUser:(NSString *)user;
- (id)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
