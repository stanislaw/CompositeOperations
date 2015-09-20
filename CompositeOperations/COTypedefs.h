//
//  COTypedefs.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 20/09/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const COErrorDomain;
FOUNDATION_EXPORT NSString *const COGenericException;

@class COOperation;

@protocol COSequentialTask <NSObject>
- (COOperation *)nextOperationAfterOperation:(COOperation *)previousOperationOrNil;
@end

@protocol COParallelTask <NSObject>
- (NSArray *)operations;
@end
