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

@required
@property (readonly, nullable) id result;
@property (readonly, nullable) id error;
@property (assign) BOOL hasLeftGroup;

@end

