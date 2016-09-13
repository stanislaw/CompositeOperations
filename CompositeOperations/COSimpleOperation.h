//
// CompositeOperations
//
// CompositeOperations/COSimpleOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COAbstractOperation.h"

@interface COSimpleOperation : COAbstractOperation

@property (readonly, nullable) id result;
@property (readonly, nullable) id error;

@property (copy, nullable) void (^completion)(id _Nullable result, id _Nullable error);

- (void)finishWithResult:(nonnull id)result;
- (void)rejectWithError:(nonnull id)error;

@end
