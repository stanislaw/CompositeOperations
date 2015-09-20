//
//  COCompositeOperation.h
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 19/09/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/COTypedefs.h>
#import <CompositeOperations/COOperation.h>

@interface COCompositeOperation : COOperation
- (id)initWithOperations:(NSArray *)operations runInParallel:(BOOL)parallel;
- (id)initWithSequentialTask:(id <COSequentialTask>)sequentialTask;
@end
