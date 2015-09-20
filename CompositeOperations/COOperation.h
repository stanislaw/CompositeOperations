//
// CompositeOperations
//
// CompositeOperations/COOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>
#import <CompositeOperations/COTypedefs.h>

typedef NS_ENUM(NSUInteger, COOperationErrorCode) {
    COOperationErrorRejected = 0,
    COOperationErrorCancelled
};

FOUNDATION_EXPORT NSString *const COOperationErrorKey;

@interface COOperation : NSOperation <COOperation>
@end
