//
// CompositeOperations
//
// CompositeOperations/COTypedefs.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const COErrorDomain;
FOUNDATION_EXPORT NSString *const COGenericException;

@class COOperation;

@protocol COAbstractOperation <NSObject>

@property (readonly) id result;
@property (readonly) id error;

@end

@protocol COSequence <NSObject>
- (NSOperation <COAbstractOperation> *)nextOperationAfterOperation:(NSOperation <COAbstractOperation> *)previousOperationOrNil;
@end
