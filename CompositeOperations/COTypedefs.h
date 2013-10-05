@class SAOperation;
@class SASyncOperation;
@class SATransactionalOperation;
@class SACascadeOperation;

@compatibility_alias SACascade SACascadeOperation;
@compatibility_alias SATransaction SATransactionalOperation;

// Operation blocks
typedef void (^SABlock)(void);
typedef void (^SAOperationBlock)(SAOperation *operation);
typedef void (^SASyncOperationBlock)(SASyncOperation *operation);
typedef void (^SATransactionalOperationBlock)(SATransactionalOperation *transactionalOperation);
typedef void (^SACascadeOperationBlock)(SACascadeOperation *cascadeOperation);

// Completion and cancellation blocks
// Gotcha: in the following typedef the second "void" is important to have overloading picked up
typedef void (^SACompletionBlock)(void);
typedef void (^SACancellationBlockForOperation)(void);
typedef void (^SACancellationBlockForTransactionalOperation)(SATransactionalOperation *transactionalOperation);
typedef void (^SACancellationBlockForCascadeOperation)(SACascadeOperation *cascadeOperation);

typedef void (^SAModificationBlock)(id data);
