//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COOperation.h"

@interface COParallelCompositeOperation : COOperation
- (id)initWithOperations:(NSArray *)operations;
@end
