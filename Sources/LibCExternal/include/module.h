#pragma once

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__)
    //define something for Windows (32-bit and 64-bit, this part is common)
    #ifdef _WIN64
        //define something for Windows (64-bit only)
    #else
        //define something for Windows (32-bit only)
    #endif

    #include "os_windows.h"
#elif __APPLE__
    #include <TargetConditionals.h>
    #if TARGET_IPHONE_SIMULATOR
         // iOS, tvOS, or watchOS Simulator
    #elif TARGET_OS_MACCATALYST
         // Mac's Catalyst (ports iOS API into Mac, like UIKit).
    #elif TARGET_OS_IPHONE
        // iOS, tvOS, or watchOS device
    #elif TARGET_OS_MAC
        // Other kinds of Apple platforms
    #else
    #error "Unknown Apple platform"
    #endif

    #include "os_apple.h"
#elif __ANDROID__
    // Below __linux__ check should be enough to handle Android,
    // but something may be unique to Android.

    #include "os_android.h"
#elif __linux__
    // linux

    #include "os_linux.h"
#elif __wasi__

    #include "os_wasi.h"
#else
#error "Unknown compiler"
#endif
