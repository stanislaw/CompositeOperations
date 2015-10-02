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
#import <CompositeOperations/COSequence.h>

@interface COCompositeOperation : COAbstractOperation

@property (readonly) NSArray *result;
@property (readonly) NSArray <NSError *> *error;

@property (copy) void (^completion)(NSArray *results, NSArray <NSError *> *errors);

- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations
           runInParallel:(BOOL)parallel;

- (id)initWithSequence:(id<COSequence>)sequence;

@end
