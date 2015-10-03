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

@property (readonly) id result;
@property (readonly) id error;

@end

