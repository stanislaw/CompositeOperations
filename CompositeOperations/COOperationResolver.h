#import <Foundation/Foundation.h>
#import "COTypedefs.h"

@class COOperation;

@protocol COOperationResolver <NSObject>

- (void)resolveOperation:(COOperation *)operation;
- (void)resolveOperation:(COOperation *)operation usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(COCompletionBlock)fallbackHandler;

@end

@interface COOperationResolver : NSObject <COOperationResolver>

@property NSUInteger defaultNumberOfTimesToRerunOperation;
@property NSUInteger defaultPauseInSecondsBeforeNextRunOfOperation;

@end

@interface COOperationResolver ()

- (void)awakeOperation:(COOperation *)operation times:(NSUInteger)times eachAfterTimeInterval:(NSTimeInterval)timeInterval withAwakeBlock:(COOperationBlock)awakeBlock fallbackHandler:(COCompletionBlock)fallbackHandler;

@end
