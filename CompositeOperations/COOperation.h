//
// CompositeOperations
//
// CompositeOperations/COOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>

@protocol COOperation <NSObject>

- (void)finish;
- (void)finishWithResult:(id)result;
- (void)reject;
- (void)rejectWithError:(NSError *)error;

@property (readonly) id result;
@property (readonly) NSError *error;

@end

@interface COOperation : NSOperation <COOperation>
@end
