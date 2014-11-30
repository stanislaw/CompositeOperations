//
// CompositeOperations
//
// CompositeOperations/COOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, COOperationErrorCode) {
    COOperationErrorRejected = 0,
    COOperationErrorCancelled
};

FOUNDATION_EXPORT NSString *const COErrorDomain;
FOUNDATION_EXPORT NSString *const COOperationErrorKey;

@protocol COOperation <NSObject>

- (void)finish;
- (void)finishWithResult:(id)result;
- (void)reject;
- (void)rejectWithError:(NSError *)error;

@property (readonly) id result;
@property (readonly) NSError *error;

@end

@interface COOperation : NSOperation <COOperation>
@end
