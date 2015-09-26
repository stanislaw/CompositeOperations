//
// CompositeOperations
//
// CompositeOperations/COCompositeOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COTypedefs.h>
#import <CompositeOperations/COAbstractOperation.h>

@protocol COSequence <NSObject>
- (NSOperation <COAbstractOperation> *)nextOperationAfterOperation:(NSOperation <COAbstractOperation> *)previousOperationOrNil;
@end

@protocol COCompositeOperation <COAbstractOperation>

@property (readonly) NSArray *result;
@property (readonly) NSArray *error;

@property (copy) void (^completion)(NSArray *results, NSArray *errors);

@end

@interface COCompositeOperation : COAbstractOperation <COCompositeOperation>
- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel;
- (id)initWithSequence:(id<COSequence>)sequence;
@end
