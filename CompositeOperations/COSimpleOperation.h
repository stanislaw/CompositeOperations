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

@property (readonly, nullable) id result;
@property (readonly, nullable) NSError *error;

@property (copy, nullable) void (^completion)(id _Nullable result, NSError * _Nullable error);

- (void)finish;
- (void)finishWithResult:(nonnull id)result;
- (void)reject;
- (void)rejectWithError:(nonnull NSError *)error;

@end
