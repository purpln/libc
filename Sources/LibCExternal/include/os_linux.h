#pragma once

#include <sys/epoll.h>
#include <sys/eventfd.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <sys/sysinfo.h>
#include <sys/timerfd.h>
#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <sched.h>
#include <unistd.h>

static inline uint32_t gettid() {
    static __thread uint32_t tid = 0;
    
    if (tid == 0) {
        tid = syscall(SYS_gettid);
    }
    
    return tid;
}
