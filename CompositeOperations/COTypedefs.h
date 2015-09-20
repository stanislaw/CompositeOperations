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

@protocol COOperation <NSObject>

@property (readonly) id result;
@property (readonly) NSError *error;

@property (copy) void (^completion)(id result, NSError *error);

- (void)finish;
- (void)finishWithResult:(id)result;
- (void)reject;
- (void)rejectWithError:(NSError *)error;

@end

@protocol COSequence <NSObject>
- (NSOperation <COOperation> *)nextOperationAfterOperation:(NSOperation <COOperation> *)previousOperationOrNil;
@end
