//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COCompositeOperation.h>

FOUNDATION_EXPORT NSString *const COParallelOperationErrorsKey;

@interface COParallelOperation : COCompositeOperation
- (id)initWithOperations:(NSArray *)operations NS_DESIGNATED_INITIALIZER;
- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
@end
