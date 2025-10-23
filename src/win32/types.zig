const std = @import("std");
const windows = std.os.windows;

const Alloc = std.mem.Allocator;

const L = std.unicode.utf8ToUtf16LeStringLiteral;
const LAlloc = std.unicode.utf8ToUtf16LeAllocZ;

const CW_USE_DEFAULT: i32 = -2147483648;

pub const WindowClassStyle = enum(u32) {
    byte_align_client = 0x1000,
    h_redraw = 0x0002,
};

var storedWindProcFn: *windowProc = undefined;

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
    overlapped_window = (@intFromEnum(WindowSingleStyles.overlapped) |
        @intFromEnum(WindowSingleStyles.caption) |
        @intFromEnum(WindowSingleStyles.sys_menu) |
        @intFromEnum(WindowSingleStyles.thick_frame) |
        @intFromEnum(WindowSingleStyles.minimize_box) |
        @intFromEnum(WindowSingleStyles.maximize_box)),
};

const GetModuleFlag = enum(u32) {
    from_address = 0x00000004,
    pin = 0x00000001,
    unchanged_refcount = 0x00000002,
};

pub const WindowStylesExtended = enum(u32) {
    accept_files = 0x00000010,
    app_window = 0x00040000,
    client_edge = 0x00000200,
    composited = 0x02000000,
    context_help = 0x00000400,
    control_parent = 0x00010000,
    dlg_modal_frame = 0x00000001,
    layered = 0x00080000,
    layout_rtl = 0x00400000,
    left = 0x00000000,
    left_scrollbar = 0x00004000,
    // ltr_reading = 0x00000000,
    mdi_child = 0x00000040,
    no_active = 0x08000000,
};

const styleEnum = enum { single, combined };

pub const WindowStyles = union(styleEnum) {
    single: WindowSingleStyles,
    combined: CombinedWindowStyles,
};
fn wndProc(
    hwnd: Handle,
    uMsg: u32,
    wParam: windows.WPARAM,
    lParam: windows.LPARAM,
) callconv(.winapi) windows.LRESULT {
    return storedWindProcFn(hwnd, uMsg, wParam, lParam);
}
pub extern "kernel32" fn GetModuleHandleW(
    lpModuleName: ?[*:0]const u16,
) callconv(.winapi) ?windows.HINSTANCE;
pub extern "kernel32" fn GetModuleHandleExW(
    dwFlags: u32,
    lpModuleName: ?[*:0]const u16,
    phModule: ?Handle,
) callconv(.winapi) windows.BOOL;

const WindowsSystemError = error{
    Invalid_Parameter,
    Unknow_Error,
    Mod_Not_Found,
    Success,
};

fn handlePossibleError() ?WindowsSystemError {
    var system_error: ?WindowsSystemError = null;
    const errCode = GetLastError();

    if (!isCodeSuccessful(errCode)) {
        std.log.err("Got error code {d} while creating window\n", .{errCode});
        system_error = mapSystemError(errCode);
        std.log.err("Got err {}", .{system_error.?});
    }
    return system_error;
}

fn isCodeSuccessful(errorCode: u32) bool {
    return errorCode == 0;
}

fn mapSystemError(errorCode: u32) WindowsSystemError {
    return switch (errorCode) {
        0 => WindowsSystemError.Success,
        87 => WindowsSystemError.Invalid_Parameter,
        126 => WindowsSystemError.Mod_Not_Found,

        else => WindowsSystemError.Unknow_Error,
    };
}

const WindowProc = fn (
    hwnd: windows.HWND,
    uMsg: u32,
    wParam: windows.WPARAM,
    lParam: windows.LPARAM,
) callconv(.winapi) windows.LRESULT;

extern fn ShowWindow(hwnd: Handle, nCmdShow: u32) callconv(.winapi) windows.BOOL;

pub const windowProc = fn (
    handle: Handle,
    message: u32,
    wParam: usize,
    lParam: isize,
) isize;

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
    size: u32 = @sizeOf(WindowClass),
    style: WindowClassStyle = .h_redraw,
    win_proc: *windowProc,
    cls_extra: i32 = 0,
    wnd_extra: i32 = 0,
    instance: windows.HINSTANCE,
    icon: ?windows.HICON = null,
    cursor: ?windows.HCURSOR = null,
    background: ?windows.HBRUSH = null,
    menu_name: ?[]const u8 = null,
    class_name: ?[]const u8 = null,
    icon_sm: ?windows.HICON = null,
};

extern "kernel32" fn RegisterClassExW(window_class: ?*WindowClass) callconv(.winapi) u16;
extern "kernel32" fn GetLastError() callconv(.winapi) u32;

pub fn RegisterClass(alloc: Alloc, wnd_class: WinClass) !u16 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const arenaAlloc = arena.allocator();
    storedWindProcFn = wnd_class.win_proc;
    const menu_name: ?[*:0]u16 = if (wnd_class.menu_name == null) null else try LAlloc(arenaAlloc, wnd_class.menu_name.?);
    const class_name: ?[*:0]u16 = if (wnd_class.class_name == null) null else try LAlloc(arenaAlloc, wnd_class.class_name.?);
    const class_config: WindowClass = .{
        .cbSize = wnd_class.size,
        .style = @intFromEnum(wnd_class.style),
        .lpfnWndProc = @constCast(&wndProc),
        .cbClsExtra = wnd_class.cls_extra,
        .cbWndExtra = wnd_class.wnd_extra,
        .hInstance = wnd_class.instance,
        .hIcon = wnd_class.icon,
        .hCursor = wnd_class.cursor,
        .hbrBackground = wnd_class.background,
        .lpszMenuName = menu_name,
        .lpszClassName = class_name,
        .hIconSm = wnd_class.icon_sm,
    };
    // std.debug.print("class config {}", .{@constCast(&class_config)});
    const res = RegisterClassExW(@constCast(&class_config));
    if (res == 0) {
        const err = handlePossibleError();
        if (err != null) {
            return err.?;
        }
    }
    return res;
}

extern "kernel32" fn CreateWindowExW(
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
    const instance = GetModuleHandleW(null);
    const err = handlePossibleError();
    if (err != null) {
        return err.?;
    }
    return instance.?;
}

const CreateWindowConfig = struct {
    ex_style: WindowStylesExtended = .left,
    class_name: []const u8 = "New Class",
    window_name: []const u8 = "New Window",
    style: WindowStyles = .{ .combined = .overlapped_window },
    X: i32 = CW_USE_DEFAULT,
    Y: i32 = CW_USE_DEFAULT,
    width: i32 = CW_USE_DEFAULT,
    height: i32 = CW_USE_DEFAULT,
    parent_handle: ?Handle = null,
    menu: ?windows.HMENU = null,
    instance: ?windows.HINSTANCE = null,
    param: ?windows.LPVOID = null,
};

pub fn CreateWindow(
    alloc: Alloc,
    config: CreateWindowConfig,
) !Handle {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const arenaAlloc = arena.allocator();
    const style_in_u32: u32 = @intFromEnum(config.style);
    const ex_style_in_u32: u32 = @intFromEnum(config.ex_style);
    const class_name: [*:0]u16 = try LAlloc(arenaAlloc, config.class_name);
    const window_name: [*:0]u16 = try LAlloc(arenaAlloc, config.window_name);
    std.debug.print("\nInstance: {}, \n", .{config.instance.?});
    const handle = CreateWindowExW(
        ex_style_in_u32,
        class_name,
        window_name,
        style_in_u32,
        config.X,
        config.Y,
        config.width,
        config.height,
        config.parent_handle,
        config.menu,
        config.instance,
        config.param,
    );
    const err = handlePossibleError();
    if (err != null) {
        return err.?;
    }
    return handle.?;
}

pub const WindowShow = enum(u32) {
    hide = 0,
    normal = 1,
    show_minimize = 2,
    maximize = 3,
    no_active = 4,
    show = 5,
    minimize = 6,
    show_min_no_active = 7,
    show_na = 8,
    restore = 9,
    show_default = 10,
    force_minimize = 11,
};

pub fn showWindow(handle: Handle, show: WindowShow) bool {
    const res = ShowWindow(handle, @intFromEnum(show));
    var isWindowPreviouslyShown = false;
    if (res != @as(c_int, 0)) isWindowPreviouslyShown = true;
    return isWindowPreviouslyShown;
}
