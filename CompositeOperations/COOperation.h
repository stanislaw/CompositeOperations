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

FOUNDATION_EXPORT NSString *const COOperationErrorKey;

@protocol COOperation <NSObject>

@property (readonly) id result;
@property (readonly) NSError *error;

@property (copy) void (^completion)(id result, NSError *error);

- (void)finish;
- (void)finishWithResult:(id)result;
- (void)reject;
- (void)rejectWithError:(NSError *)error;

@end

@interface COOperation : NSOperation <COOperation>
@end
