@class COOperation;
@class COSyncOperation;
@class COTransactionalOperation;
@class COCascadeOperation;

@compatibility_alias COCascade COCascadeOperation;
@compatibility_alias COTransaction COTransactionalOperation;

// Operation blocks
typedef void (^COBlock)(void);
typedef void (^COOperationBlock)(COOperation *operation);
typedef void (^COSyncOperationBlock)(COSyncOperation *operation);
typedef void (^COTransactionalOperationBlock)(COTransactionalOperation *transactionalOperation);
typedef void (^COCascadeOperationBlock)(COCascadeOperation *cascadeOperation);

// Completion and cancellation blocks
// Gotcha: in the following typedef the second "void" is important to have overloading picked up
typedef void (^COCompletionBlock)(void);
typedef void (^COCancellationBlockForOperation)(void);
typedef void (^COCancellationBlockForTransactionalOperation)(COTransactionalOperation *transactionalOperation);
typedef void (^COCancellationBlockForCascadeOperation)(COCascadeOperation *cascadeOperation);

typedef void (^COModificationBlock)(id data);
