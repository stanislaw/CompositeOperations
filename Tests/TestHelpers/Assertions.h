
static inline void dispatch_once_and_next_time(dispatch_once_t *oncePredicate, dispatch_block_t onceBlock, dispatch_block_t nextTimesBlock) {
    if (*oncePredicate) {
        [nextTimesBlock invoke];
    }

    dispatch_once(oncePredicate, ^{
        [onceBlock invoke];
    });
}

#define __dispatch_once_and_next_time_auto(token, onceBlock, nextTimesBlock) \
    static dispatch_once_t token; \
    dispatch_once_and_next_time(&token, onceBlock, nextTimesBlock);

#define dispatch_once_and_next_time_auto(onceBlock, nextTimeBlock) \
    __dispatch_once_and_next_time_auto(__NSX_PASTE__(__dispatch_once_and_next_time_auto, __COUNTER__), onceBlock, nextTimeBlock)


#define __AssertShouldNotReachHereTwice(token) \
    static dispatch_once_t token; \
    dispatch_once_and_next_time(&token, ^{ \
    \
    }, ^{ \
        abort(); \
    })

#define AssertShouldNotReachHereTwice() \
    __AssertShouldNotReachHereTwice(__NSX_PASTE__(__shouldNotReachHereTwiceToken, __COUNTER__))
