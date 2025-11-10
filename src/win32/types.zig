const std = @import("std");
const win32_windows_messaging = @import("Win32").ui.windows_and_messaging;
const win32_foundation = @import("Win32").foundation;
const win32_core = @import("Win32");
// TODO: We need to ensure to remove everything call to only specific ones;
const win32 = @import("Win32").everything;

const Alloc = std.mem.Allocator;

const L = std.unicode.utf8ToUtf16LeStringLiteral;
const LAlloc = std.unicode.utf8ToUtf16LeAllocZ;
pub const CW_USE_DEFAULT = win32_windows_messaging.CW_USEDEFAULT;
const HBRUSH = @import("Win32").graphics.gdi.HBRUSH;
pub const HWND = win32_foundation.HWND;

pub const WindowClassStyle = enum {
    byte_align_client,
    h_redraw,
};

var storedWindProcFn: *windowProc = undefined;

const GetModuleFlag = enum(u32) {
    from_address = 0x00000004,
    pin = 0x00000001,
    unchanged_refcount = 0x00000002,
};

pub const WindowStylesExtended = enum {
    accept_files,
    app_window,
    client_edge,
    composited,
    context_help,
    control_parent,
    dlg_modal_frame,
    layered,
    layout_rtl,
    left,
    left_scrollbar,
    // ltr_reading = 0x00000000,
    mdi_child,
    no_active,
};

pub const WindowStyles = enum {
    border,
    overlapped,
    caption,
    sys_menu,
    thick_frame,
    minimize_box,
    maximize_box,
    overlapped_window,
};
fn wndProc(
    hwnd: HWND,
    uMsg: u32,
    wParam: win32_foundation.WPARAM,
    lParam: win32_foundation.LPARAM,
) callconv(.winapi) win32_foundation.LRESULT {
    return storedWindProcFn(hwnd, uMsg, wParam, lParam);
}
// pub extern "kernel32" fn win32.GetModuleHaneGetModuleHandleW(
//     lpModuleName: ?[*:0]const u16,
// ) callconv(.winapi) ?win32.HINSTANCE;
// pub extern "kernel32" fn GetModuleHandleExW(
//     dwFlags: u32,
//     lpModuleName: ?[*:0]const u16,
//     phModule: ?Handle,
// ) callconv(.winapi) windows.BOOL;

const WindowsSystemError = error{
    Invalid_Parameter,
    Unknow_Error,
    Mod_Not_Found,
    Success,
};

fn handlePossibleError() ?WindowsSystemError {
    var system_error: ?WindowsSystemError = null;
    const errCode: u32 = @intFromEnum(win32_foundation.GetLastError());

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
    hwnd: HWND,
    uMsg: u32,
    wParam: win32_foundation.WPARAM,
    lParam: win32_foundation.LPARAM,
) callconv(.winapi) win32_foundation.LRESULT;

// extern fn ShowWindow(hwnd: HWND, nCmdShow: u32) callconv(.winapi) windows.BOOL;

pub const windowProc = fn (
    handle: HWND,
    message: u32,
    wParam: usize,
    lParam: isize,
) isize;

// const WindowClass = extern struct {
//     cbSize: u32,
//     style: u32,
//     lpfnWndProc: ?*WindowProc,
//     cbClsExtra: i32,
//     cbWndExtra: i32,
//     hInstance: win32.HINSTANCE,
//     hIcon: ?win32.HICON,
//     hCursor: ?win32.HCURSOR,
//     hbrBackground: ?win32.HBRUSH,
//     lpszMenuName: ?[*:0]const u16,
//     lpszClassName: ?[*:0]const u16,
//     hIconSm: ?windows.HICON,
// };
pub const WinClass = struct {
    size: u32 = @sizeOf(win32_windows_messaging.WNDCLASSEXW),
    style: WindowClassStyle = .h_redraw,
    win_proc: *windowProc,
    cls_extra: i32 = 0,
    wnd_extra: i32 = 0,
    instance: win32.HINSTANCE,
    icon: ?win32_windows_messaging.HICON = null,
    cursor: ?win32_windows_messaging.HCURSOR = null,
    background: ?HBRUSH = null,
    menu_name: ?[]const u8 = null,
    class_name: ?[]const u8 = null,
    icon_sm: ?win32_windows_messaging.HICON = null,
};

fn mapWndClassStyle(style: WindowClassStyle) win32_windows_messaging.WNDCLASS_STYLES {
    return switch (style) {
        .byte_align_client => win32_windows_messaging.CS_BYTEALIGNCLIENT,
        .h_redraw => win32_windows_messaging.CS_HREDRAW,
    };
}

fn mapWindowStyleExtended(style: WindowStylesExtended) win32_windows_messaging.WINDOW_EX_STYLE {
    return switch (style) {
        .accept_files => win32_windows_messaging.WS_EX_ACCEPTFILES,
        .app_window => win32_windows_messaging.WS_EX_APPWINDOW,
        .client_edge => win32_windows_messaging.WS_EX_CLIENTEDGE,
        .composited => win32_windows_messaging.WS_EX_COMPOSITED,
        .context_help => win32_windows_messaging.WS_EX_CONTEXTHELP,
        .control_parent => win32_windows_messaging.WS_EX_CONTROLPARENT,
        .dlg_modal_frame => win32_windows_messaging.WS_EX_DLGMODALFRAME,
        .layered => win32_windows_messaging.WS_EX_LAYERED,
        .layout_rtl => win32_windows_messaging.WS_EX_LAYOUTRTL,
        .left => win32_windows_messaging.WS_EX_LEFT,
        .left_scrollbar => win32_windows_messaging.WS_EX_LEFTSCROLLBAR,
        .mdi_child => win32_windows_messaging.WS_EX_MDICHILD,
        .no_active => win32_windows_messaging.WS_EX_NOACTIVATE
    };
}

fn mapWindowStyle(style: WindowStyles) win32_windows_messaging.WINDOW_STYLE {
    return switch (style) {
        .overlapped_window => win32_windows_messaging.WS_OVERLAPPEDWINDOW,
        .border => win32_windows_messaging.WS_BORDER,
        .overlapped => win32_windows_messaging.WS_OVERLAPPED,
        .caption => win32_windows_messaging.WS_CAPTION,
        .maximize_box => win32_windows_messaging.WS_MAXIMIZEBOX,
        .minimize_box => win32_windows_messaging.WS_MINIMIZEBOX,
        .sys_menu => win32_windows_messaging.WS_SYSMENU,
        .thick_frame => win32_windows_messaging.WS_THICKFRAME,
    };
}

pub fn RegisterClass(alloc: Alloc, wnd_class: WinClass) !u16 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const arenaAlloc = arena.allocator();
    storedWindProcFn = wnd_class.win_proc;
    const menu_name: ?[*:0]u16 = if (wnd_class.menu_name == null) null else try LAlloc(arenaAlloc, wnd_class.menu_name.?);
    const class_name: ?[*:0]u16 = if (wnd_class.class_name == null) null else try LAlloc(arenaAlloc, wnd_class.class_name.?);
    const class_config: win32_windows_messaging.WNDCLASSEXW = .{
        .cbSize = wnd_class.size,
        .style = mapWndClassStyle(wnd_class.style),
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
    const res = win32_windows_messaging.RegisterClassExW(@constCast(&class_config));
    if (res == 0) {
        const err = handlePossibleError();
        if (err != null) {
            return err.?;
        }
    }
    return res;
}

// extern "kernel32" fn CreateWindowExW(
//     dwExStyle: u32,
//     lpClassName: ?[*:0]const u16,
//     lpWindowName: ?[*:0]const u16,
//     dwStyle: u32,
//     X: i32,
//     Y: i32,
//     nWidth: i32,
//     nHeight: i32,
//     hWndParent: ?Handle,
//     hMenu: ?windows.HMENU,
//     hInstance: ?windows.HINSTANCE,
//     lpParam: ?windows.LPVOID,
// ) callconv(.winapi) ?Handle;

pub fn GetCurrentHandleInstance() !win32.HINSTANCE {
    const instance = win32.GetModuleHandleW(null);
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
    style: WindowStyles = .overlapped_window,
    X: i32 = CW_USE_DEFAULT,
    Y: i32 = CW_USE_DEFAULT,
    width: i32 = CW_USE_DEFAULT,
    height: i32 = CW_USE_DEFAULT,
    parent_handle: ?HWND = null,
    menu: ?win32_windows_messaging.HMENU = null,
    instance: ?win32_foundation.HINSTANCE = null,
    param: ?*anyopaque = null,
};

pub fn CreateWindow(
    alloc: Alloc,
    config: CreateWindowConfig,
) !HWND {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const arenaAlloc = arena.allocator();
    const style_in_u32: win32_windows_messaging.WINDOW_STYLE = mapWindowStyle(config.style);
    const ex_style_in_u32: win32_windows_messaging.WINDOW_EX_STYLE = mapWindowStyleExtended(config.ex_style);
    const class_name: [*:0]u16 = try LAlloc(arenaAlloc, config.class_name);
    const window_name: [*:0]u16 = try LAlloc(arenaAlloc, config.window_name);
    std.debug.print("\nInstance: {}, \n", .{config.instance.?});

    const handle = win32_windows_messaging.CreateWindowExW(
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
    hide,
    normal,
    show_minimize,
    maximize,
    no_active,
    show,
    minimize,
    show_min_no_active,
    show_na,
    restore,
    show_default,
    force_minimize,
};

fn mapWindowShow(show: WindowShow) win32_windows_messaging.SHOW_WINDOW_CMD {
    return switch (show) {
        .hide => win32_windows_messaging.SW_HIDE,
        .normal => win32_windows_messaging.SW_NORMAL,
        .show_minimize => win32_windows_messaging.SW_SHOWMINIMIZED,
        .maximize => win32_windows_messaging.SW_MAXIMIZE,
        .no_active => win32_windows_messaging.SW_SHOWNOACTIVATE,
        .show => win32_windows_messaging.SW_SHOW,
        .minimize => win32_windows_messaging.SW_MINIMIZE,
        .show_min_no_active => win32_windows_messaging.SW_SHOWMINNOACTIVE,
        .show_na => win32_windows_messaging.SW_SHOWNA,
        .restore => win32_windows_messaging.SW_RESTORE,
        .show_default => win32_windows_messaging.SW_SHOWDEFAULT,
        .force_minimize => win32_windows_messaging.SW_FORCEMINIMIZE,
    };
}

pub fn showWindow(handle: HWND, show: WindowShow) bool {
    const res = win32_windows_messaging.ShowWindow(
        handle,
        mapWindowShow(show),
    );
    var isWindowPreviouslyShown = false;
    if (res != 0) isWindowPreviouslyShown = true;
    return isWindowPreviouslyShown;
}
