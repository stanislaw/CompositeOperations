//
// CompositeOperations
//
// CompositeOperations/__COSequentialOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COCompositeOperation.h>

@interface __COSequentialOperation : COCompositeOperation
- (id)initWithSequence:(id<COSequence>)sequence NS_DESIGNATED_INITIALIZER;
- (id)init NS_UNAVAILABLE;
@end
