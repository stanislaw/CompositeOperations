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

@interface COCompositeOperation : COOperation
- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel;
- (id)initWithSequence:(id<COSequence>)sequence;
@end
