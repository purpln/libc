#pragma once

#include <module.h>

char *_Nullable *_Null_unspecified _platform_shims_get_environ(void);

void _platform_shims_lock_environ(void);
void _platform_shims_unlock_environ(void);
