const std = @import("std");
const windows = std.os.windows;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

const CW_USE_DEFAULT: i32 = -2147483648;

pub const WindowClassStyle = enum(u32) {
    byte_align_client = 0x1000,
};

pub const WindowSingleStyles = enum(u32) {
    border = 0x00800000,
    overlapped = 0x00000000,
    caption = 0x00C00000,
    sys_menu = 0x00080000,
    thick_frame = 0x00040000,
    minimize_box = 0x00020000,
    maximize_box = 0x00010000,
};

pub const CombinedWindowStyles = enum(u32) {
    overlapped_window = (WindowSingleStyles.overlapped |
        WindowSingleStyles.caption |
        WindowSingleStyles.sys_menu |
        WindowSingleStyles.thick_frame |
        WindowSingleStyles.minimize_box |
        WindowSingleStyles.maximize_box),
};

pub const WindowStylesExtended = enum(u32) {
    accept_files = 0x00000010,
};

pub const WindowStyles = union {
    single: WindowSingleStyles,
    combined: CombinedWindowStyles,
};

pub const WindowProc = fn (
    hwnd: windows.HWND,
    uMsg: u32,
    wParam: windows.WPARAM,
    lParam: windows.LPARAM,
) callconv(.winapi) windows.LRESULT;

pub const Handle = windows.HWND;
const WindowClass = extern struct {
    cbSize: u32,
    style: u32,
    lpfnWndProc: ?*WindowProc,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: windows.HINSTANCE,
    hIcon: ?windows.HICON,
    hCursor: ?windows.HCURSOR,
    hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: ?[*:0]const u16,
    hIconSm: ?windows.HICON,
};
pub const WinClass = struct {
    size: u32,
    style: WindowClassStyle,
    win_proc: ?*WindowProc,
    cls_extra: i32,
    wnd_extra: i32,
    instance: windows.HINSTANCE,
    icon: ?windows.HICON,
    cursor: ?windows.HCURSOR,
    background: ?windows.HBRUSH,
    menu_name: []const u8,
    class_name: []const u8,
    icon_sm: ?windows.HICON,
};

extern fn RegisterClassExW(window_class: ?*WindowClass) callconv(.winapi) u16;

pub fn RegisterClass(wnd_class: WinClass) u16 {
    const class_config: WindowClass = .{
        .cbSize = wnd_class.size,
        .style = @intFromEnum(wnd_class.style),
        .lpfnWndProc = wnd_class.win_proc,
        .cbClsExtra = wnd_class.cls_extra,
        .cbWndExtra = wnd_class.wnd_extra,
        .hInstance = wnd_class.instance,
        .hIcon = wnd_class.icon,
        .hCursor = wnd_class.cursor,
        .hbrBackground = wnd_class.background,
        .lpszMenuName = wnd_class.menu_name,
        .lpszClassName = wnd_class.class_name,
        .hIconSm = wnd_class.icon_sm,
    };
    RegisterClassExW(&class_config);
}

extern fn CreateWindowExW(
    dwExStyle: u32,
    lpClassName: ?[*:0]const u16,
    lpWindowName: ?[*:0]const u16,
    dwStyle: u32,
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

const CreateWindowConfig = struct {
    ex_style: WindowStylesExtended,
    class_name: []const u8 = "New Class",
    window_name: []const u8 = "New Window",
    style: WindowStyles = .{ .combined = .overlapped_window },
    X: i32 = CW_USE_DEFAULT,
    Y: i32 = CW_USE_DEFAULT,
    width: i32 = CW_USE_DEFAULT,
    height: i32 = CW_USE_DEFAULT,
    parent_handle: ?Handle,
    menu: ?windows.HMENU,
    instance: ?windows.HINSTANCE,
    param: ?windows.LPVOID,
};

pub fn CreateWindow(
    config: CreateWindowConfig,
) !Handle {
    const style_in_u8: u8 = @intFromEnum(config.style);
    const ex_style_in_u8: u8 = @intFromEnum(config.ex_style);
    CreateWindowExW(
        ex_style_in_u8,
        L(config.class_name),
        L(config.window_name),
        style_in_u8,
        config.X,
        config.Y,
        config.width,
        config.height,
        config.parent_handle,
        config.menu,
        config.instance,
        config.param,
    );
}
fn testd() void {}
