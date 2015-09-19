
#define __CO_PASTE__(A, B) A##B

static inline void dispatch_once_and_next_time(dispatch_once_t *oncePredicate, dispatch_block_t onceBlock, dispatch_block_t nextTimesBlock) {
    if (*oncePredicate) {
        [nextTimesBlock invoke];
    }

    dispatch_once(oncePredicate, ^{
        [onceBlock invoke];
    });
}

#define __dispatch_once_and_next_time_auto(token, onceBlock, nextTimesBlock) \
    do {                                                                     \
        static dispatch_once_t token;                                        \
        dispatch_once_and_next_time(&token, onceBlock, nextTimesBlock);      \
    } while (0);

#define dispatch_once_and_next_time_auto(onceBlock, nextTimeBlock) \
    __dispatch_once_and_next_time_auto(__CO_PASTE__(__dispatch_once_and_next_time_auto, __COUNTER__), onceBlock, nextTimeBlock)

#define __AssertShouldNotReachHereTwice(token)           \
    static dispatch_once_t token;                        \
    dispatch_once_and_next_time(&token, ^{               \
                                                         \
                                }, ^{ \
        abort(); \
    })

#define AssertShouldNotReachHereTwice() \
    __AssertShouldNotReachHereTwice(__CO_PASTE__(__shouldNotReachHereTwiceToken, __COUNTER__))

#define AssertShouldNotReachHere() @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"Should not reach here: %s:%d, %s", __FILE__, __LINE__, __PRETTY_FUNCTION__] userInfo:nil]
