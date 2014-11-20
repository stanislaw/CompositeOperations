//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COOperation.h"

@interface COParallelOperation : COOperation
- (id)initWithOperations:(NSArray *)operations;
@end
