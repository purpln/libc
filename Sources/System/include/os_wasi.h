#pragma once

#include <errno.h>
#include <fcntl.h>
#include <dirent.h>
#include <time.h>

static inline int32_t _getConst_DT_DIR(void) { return DT_DIR; }

static inline int32_t _getConst_O_ACCMODE(void) { return O_ACCMODE; }
static inline int32_t _getConst_O_APPEND(void) { return O_APPEND; }
static inline int32_t _getConst_O_CREAT(void) { return O_CREAT; }
static inline int32_t _getConst_O_DIRECTORY(void) { return O_DIRECTORY; }
static inline int32_t _getConst_O_EXCL(void) { return O_EXCL; }
static inline int32_t _getConst_O_NONBLOCK(void) { return O_NONBLOCK; }
static inline int32_t _getConst_O_TRUNC(void) { return O_TRUNC; }
static inline int32_t _getConst_O_WRONLY(void) { return O_WRONLY; }

static inline int32_t _getConst_EWOULDBLOCK(void) { return EWOULDBLOCK; }
static inline int32_t _getConst_EOPNOTSUPP(void) { return EOPNOTSUPP; }

static inline clockid_t _getConst_CLOCK_MONOTONIC(void) { return CLOCK_MONOTONIC; }
static inline clockid_t _getConst_CLOCK_REALTIME(void) { return CLOCK_REALTIME; }
