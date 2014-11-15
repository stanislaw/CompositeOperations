//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>

@interface COOperation : NSOperation

- (void)main;
- (void)start;
- (void)cancel;

@property (readonly) id result;
@property (readonly) NSError *error;

@end
