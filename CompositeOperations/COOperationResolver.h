#import <Foundation/Foundation.h>
#import "SATypedefs.h"

@class SAOperation;

@protocol SAOperationResolver <NSObject>

- (void)resolveOperation:(SAOperation *)operation;
- (void)resolveOperation:(SAOperation *)operation usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(SACompletionBlock)fallbackHandler;

@end

@interface SAOperationResolver : NSObject <SAOperationResolver>

@property NSUInteger defaultNumberOfTimesToRerunOperation;
@property NSUInteger defaultPauseInSecondsBeforeNextRunOfOperation;

@end

@interface SAOperationResolver ()

- (void)awakeOperation:(SAOperation *)operation times:(NSUInteger)times eachAfterTimeInterval:(NSTimeInterval)timeInterval withAwakeBlock:(SAOperationBlock)awakeBlock fallbackHandler:(SACompletionBlock)fallbackHandler;

@end
