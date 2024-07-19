/**
 * Wait for {@link ms} milliseconds
 *
 * This function is a promisified `setTimeout`. It returns a promise that
 * resolves after {@link ms} milliseconds.
 */
export const wait = (ms: number) =>
    new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Throttle invocations of an underlying function, coalescing pending calls.
 *
 * Take a function that returns a promise, and return a new function that can be
 * called an any number of times while still ensuring that the underlying
 * function is only called a maximum of once per the specified period.
 *
 * The underlying function is immediately called if there were no calls to the
 * throttled function in the last period.
 *
 * Otherwise we start waiting. Multiple calls to the throttled function while
 * we're waiting (either for the original promise to resolve, or after that, for
 * the specified cooldown period to elapse) will all be coalesced into a single
 * call to the underlying function when we're done waiting.
 *
 * ---
 *
 * [Note: Throttle and debounce]
 *
 * There are many throttle/debounce libraries, and ideally I'd have liked to
 * just use one of them instead of reinventing such a basic and finicky wheel.
 * Then why write a bespoke one?
 *
 * -   "debounce" means that the underlying function will only be called when a
 *     particular wait time has elapsed since the last call to the _debounced_
 *     function.
 *
 * -   This behaviour, while useful sometimes, is not what we want always. If
 *     the debounced function is continuously being called, then the underlying
 *     function might never get called (since the wait time does not elapse).
 *
 * -   To avoid this starvation, some debounce implementations like lodash
 *     provide a "maxWait" option, which tells the debounced function to always
 *     call the underlying function if maxWait has elapsed.
 *
 * -   The debounced functions can trigger the underlying in two ways: leading
 *     (aka immediate) and trailing which control if the underlying should be
 *     called at the leading or the trailing edge of the time period.
 *
 * -   "throttle" can be conceptually thought of as just maxWait + leading. In
 *     fact, this is how lodash actually implements it too. So we could've used
 *     lodash, except that is a big dependency to pull for a small function.
 *
 * -   Alternatively, pThrottle is a micro-library that provide such a
 *     "throttle" primitive. However, its implementation enqueues all incoming
 *     requests to the throttled function: it still calls the underlying once
 *     per period, but eventually underlying will get called once for each call
 *     to the throttled function.
 *
 * -   There are circumstances where that would be the appropriate behaviour,
 *     but that's not what we want. We wish to trigger an async action,
 *     coalescing multiple triggers into a single one, one per period.
 *
 * -   Perhaps there are other focused and standard library that'd have what we
 *     want, but instead of spending more time searching I just wrote it from
 *     scratch for now. Indeed, I've spent more time writing about the function
 *     than the function itself.
 */
export const throttled = (underlying: () => Promise<void>, period: number) => {
    let pending = 0;

    const f = () => {
        pending += 1;
        if (pending > 1) return;
        void underlying()
            .then(() => wait(period))
            .then(() => {
                const retrigger = pending > 1;
                pending = 0;
                if (retrigger) f();
            });
    };

    return f;
};

/**
 * Await the given {@link promise} for {@link timeoutMS} milliseconds. If it
 * does not resolve within {@link timeoutMS}, then reject with a timeout error.
 *
 * Note that this does not abort {@link promise} itself - it will still get
 * resolved to completion, just its result will be ignored if it gets resolved
 * after we've already timed out.
 */
export const withTimeout = async <T>(promise: Promise<T>, ms: number) => {
    let timeoutId: ReturnType<typeof setTimeout>;
    const rejectOnTimeout = new Promise<T>((_, reject) => {
        timeoutId = setTimeout(
            () => reject(new Error("Operation timed out")),
            ms,
        );
    });
    const promiseAndCancelTimeout = async () => {
        const result = await promise;
        clearTimeout(timeoutId);
        return result;
    };
    return Promise.race([promiseAndCancelTimeout(), rejectOnTimeout]);
};
