#if os(Windows)

import WinSDK

extension Errno {
    internal init(windowsError: DWORD) {
        self.init(rawValue: _mapWindowsErrorToErrno(windowsError))
    }
}

#endif
