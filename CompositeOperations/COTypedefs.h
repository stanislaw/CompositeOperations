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

typedef NS_ENUM(NSUInteger, COOperationErrorCode) {
    COOperationErrorRejected = 0,
    COOperationErrorCancelled
};
