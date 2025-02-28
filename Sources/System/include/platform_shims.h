#pragma once

#include <module.h>

char *_Nullable *_Null_unspecified _platform_shims_get_environ(void);

void _platform_shims_lock_environ(void);
void _platform_shims_unlock_environ(void);

#if __wasi__
#include <dirent.h>

// Use shim on WASI because wasi-libc defines `d_name` as
// "flexible array member" which is not supported by
// ClangImporter yet.
static inline char * _Nonnull _platform_shims_dirent_d_name(struct dirent * _Nonnull entry) {
    return entry->d_name;
}
#endif

#if __ANDROID__
#include <android/log.h>

static inline void android_log(int prio, const char * _Nonnull tag, const char * _Nonnull str) {
    __android_log_print(prio, tag, "%s", str);
}
#endif
