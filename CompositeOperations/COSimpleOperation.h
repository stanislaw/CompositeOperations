//
// CompositeOperations
//
// CompositeOperations/COSimpleOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COTypedefs.h>
#import <CompositeOperations/COAbstractOperation.h>

@interface COSimpleOperation : COAbstractOperation

@property (readonly) id result;
@property (readonly) NSError *error;

@property (copy) void (^completion)(id result, NSError *error);

- (void)finish;
- (void)finishWithResult:(id)result;
- (void)reject;
- (void)rejectWithError:(NSError *)error;

@end
