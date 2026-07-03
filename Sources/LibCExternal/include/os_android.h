#pragma once

#include <sys/epoll.h>

static inline uint32_t _getConst_EPOLLEXCLUSIVE(void) { return EPOLLEXCLUSIVE; }
static inline uint32_t _getConst_EPOLLWAKEUP(void) { return EPOLLWAKEUP; }
static inline uint32_t _getConst_EPOLLONESHOT(void) { return EPOLLONESHOT; }
static inline uint32_t _getConst_EPOLLET(void) { return EPOLLET; }
