//
// CompositeOperations
//
// CompositeOperations/COCompositeOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COTypedefs.h>
#import <CompositeOperations/COOperation.h>

@protocol COCompositeOperation <COAbstractOperation>

@property (readonly) id result;
@property (readonly) id error;

@property (copy) void (^completion)(NSArray *results, NSArray *errors);

- (void)finish;
- (void)finishWithResult:(id)result;
- (void)reject;
- (void)rejectWithError:(NSError *)error;

@end

@interface COCompositeOperation : COOperation
- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel;
- (id)initWithSequence:(id<COSequence>)sequence;
@end
