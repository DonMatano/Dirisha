const std = @import("std");
const windows = std.os.windows;

pub const L = std.unicode.utf8ToUtf16LeStringLiteral;

pub const CW_USE_DEFAULT: i32 = -2147483648;

pub const WindowClassStyle = enum(u32) {
    byte_align_client = 0x1000,
};

pub const WindowStyles = enum(u32) {
    border = 0x00800000,
    overlapped = 0x00000000,
    caption = 0x00C00000,
    sys_menu = 0x00080000,
    thick_frame = 0x00040000,
    minimize_box = 0x00020000,
    maximize_box = 0x00010000,
};

pub const CombinedWindowStyles = enum(u32) {
    overlapped_window = (WindowStyles.overlapped |
        WindowStyles.caption |
        WindowStyles.sys_menu |
        WindowStyles.thick_frame |
        WindowStyles.minimize_box |
        WindowStyles.maximize_box),
};

pub const WindowStylesExtended = enum(u32) {
    accept_files = 0x00000010,
};

pub const WindowProc = fn (
    hwnd: windows.HWND,
    uMsg: u32,
    wParam: windows.WPARAM,
    lParam: windows.LPARAM,
) callconv(.winapi) windows.LRESULT;

pub const Handle = windows.HWND;
pub const WindowClass = extern struct {
    cbSize: u32,
    style: WindowClassStyle,
    lpfnWndProc: ?*WindowProc,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: windows.HINSTANCE,
    hIcon: ?windows.HICON,
    hCursor: ?windows.HCURSOR,
    hBursh: ?windows.HBRUSH,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: ?[*:0]const u16,
    hIconSm: ?windows.HICON,
};

pub extern fn RegisterClassExW(window_class: ?*WindowClass) callconv(.winapi) u16;

pub extern fn CreateWindowExW(
    dwExStyle: WindowStylesExtended,
    lpClassName: ?[*:0]const u16,
    lpWindowName: ?[*:0]const u16,
    dwStyle: WindowStyles,
    X: i32,
    Y: i32,
    nWidth: i32,
    nHeight: i32,
    hWndParent: ?Handle,
    hMenu: ?windows.HMENU,
    hInstance: ?windows.HINSTANCE,
    lpParam: ?windows.LPVOID,
) callconv(.winapi) ?Handle;

pub fn GetCurrentHandleInstance() !windows.HINSTANCE {
    const instance: windows.HINSTANCE = try windows.kernel32.GetModuleHandleW(null) orelse return error{CRITICAL_MODULE_NOT_FOUND};
    return instance;
}
fn testd() void {}
