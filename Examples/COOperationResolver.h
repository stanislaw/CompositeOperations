
#import <Foundation/Foundation.h>
#import "COTypedefs.h"

@class COOperation;

@protocol COOperationResolver <NSObject>

- (void)resolveOperation:(COOperation *)operation;
- (void)resolveOperation:(COOperation *)operation usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(COBlock)fallbackHandler;

@end

@interface COOperationResolver : NSObject <COOperationResolver>

@property NSUInteger numberOfResolutionsPerOperation;
@property NSUInteger pauseInSecondsBeforeNextRunOfOperation;

@end
