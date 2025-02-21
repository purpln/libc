#include <platform_shims.h>

#if __has_include(<crt_externs.h>)
#include <crt_externs.h>
#elif defined(_WIN32)
#include <stdlib.h>
#elif __has_include(<unistd.h>)
#include <unistd.h>
extern char **environ;
#endif

#if __wasi__
#include <wasi/libc-environ.h>
#endif

#if __has_include(<libc_private.h>)
#import <libc_private.h>
void _platform_shims_lock_environ(void) {
    environ_lock_np();
}

void _platform_shims_unlock_environ(void) {
    environ_unlock_np();
}
#else
void _platform_shims_lock_environ(void) { /* noop */ }
void _platform_shims_unlock_environ(void) { /* noop */ }
#endif

char ** _platform_shims_get_environ(void) {
#if __has_include(<crt_externs.h>)
    return *_NSGetEnviron();
#elif defined(_WIN32)
    return _environ;
#elif __has_include(<wasi/libc-environ.h>)
    return __wasilibc_get_environ();
#elif __has_include(<unistd.h>)
    return environ;
#endif
}
