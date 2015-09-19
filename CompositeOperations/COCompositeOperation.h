//
//  COCompositeOperation.h
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 19/09/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/CompositeOperations.h>

@interface COCompositeOperation : COOperation
- (id)initWithSequentialTask:(id<COSequentialTask>)sequentialTask;
- (id)initWithParallelTask:(id<COParallelTask>)parallelTask;
- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel;
@end
