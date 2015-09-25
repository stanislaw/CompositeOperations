//
// CompositeOperations
//
// CompositeOperations/COOperation.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <Foundation/Foundation.h>
#import <CompositeOperations/COTypedefs.h>

@protocol COAbstractOperation <NSObject>

@property (readonly) id result;
@property (readonly) id error;

@end

@interface COAbstractOperation : NSOperation <COAbstractOperation>
@end
