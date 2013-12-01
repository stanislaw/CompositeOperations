// CompositeOperations
//
// CompositeOperations/COTypedefs.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

@class COOperation;
@class COCompositeOperation;

// Operation blocks
typedef void (^COBlock)(void);
typedef void (^COOperationBlock)(COOperation *operation);
typedef void (^COCompositeOperationBlock)(COCompositeOperation *compositeOperation);

// Completion and cancellation blocks
// Gotcha: in the following typedef the second "void" is important to have overloading picked up
typedef void (^COCompletionBlock)(id result);
typedef void (^COCancellationBlockForOperation)(COOperation *operation, NSError *error);
typedef void (^COCancellationBlockForCompositeOperation)(COCompositeOperation *compositeOperation, NSError *error);

typedef id (^COModificationBlock)(id data);

typedef NS_ENUM(NSUInteger, COCompositeOperationConcurrencyType) {
    COCompositeOperationSerial = 1,
    COCompositeOperationConcurrent = 4
};
