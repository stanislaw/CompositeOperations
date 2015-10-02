//
//  COSequence.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CompositeOperations/COOperation.h>

@protocol COSequence <NSObject>

- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation <COOperation> *)previousOperationOrNil;

@end
