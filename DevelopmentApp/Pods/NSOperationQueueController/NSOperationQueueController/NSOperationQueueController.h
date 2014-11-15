// NSOperationQueueController
//
// NSOperationQueueController/NSOperationQueueController.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NSOperationQueueControllerOrder) {
    NSOperationQueueControllerOrderFIFO = 0,
    NSOperationQueueControllerOrderLIFO
};

@class NSOperationQueueController;

@protocol NSOperationQueueControllerDelegate <NSObject>

@optional
- (void)operationQueueController:(NSOperationQueueController *)controller operationDidStartExecuting:(NSOperation *)operation;
- (void)operationQueueController:(NSOperationQueueController *)controller operationDidFinish:(NSOperation *)operation;
- (void)operationQueueController:(NSOperationQueueController *)controller operationDidCancel:(NSOperation *)operation;

@end

@interface NSOperationQueueController : NSObject

- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue;

@property (strong, nonatomic) id <NSOperationQueueControllerDelegate> delegate;


// Options
@property NSOperationQueueControllerOrder order;
@property (nonatomic) NSUInteger limit;


// NSOperationQueue interface
@property (readonly) NSUInteger operationCount;
@property (readonly) NSUInteger maxConcurrentOperationCount;

- (void)addOperationWithBlock:(void(^)(void))operationBlock;
- (void)addOperation:(NSOperation *)operation;

- (void)cancelAllOperations;
- (void)cancelAndRunOutAllPendingOperations;

@property (readonly) BOOL isSuspended;
- (void)setSuspended:(BOOL)suspend;


// NSObject
- (NSString *)description;
- (NSString *)debugDescription;

@end


