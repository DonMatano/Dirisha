const win32 = @import("../win32/win32.zig");
const std = @import("std");
const w = std.os.windows;
const win32Types = win32.types;

fn wndProc(
    hndl: win32.types.Handle,
    uMsg: u32,
    wParam: w.WPARAM,
    lParam: w.LPARAM,
) callconv(.winapi) w.LRESULT {
    _ = hndl;
    _ = uMsg;
    _ = wParam;
    _ = lParam;
}

pub fn run() !void {
    // const class_name = win32Types.L("New Window Class");
    // const instance = win32Types.GetCurrentHandleInstance();

    //     const wc: win32Types.WindowClass = .{
    //         .lpfnWndProc = wndProc,
    //         .hInstance = instance,
    //         .lpszClassName = class_name,
    //     };
    //
    //     const hwnd = win32.types.CreateWindowExW(
    //         .{},
    //         class_name,
    //         win32.types.L("New Window"),
    //         .{},
    //         win32Types.CW_USE_DEFAULT,
    //         win32Types.CW_USE_DEFAULT,
    //         win32Types.CW_USE_DEFAULT,
    //         win32Types.CW_USE_DEFAULT,
    //         null,
    //         null,
    //         instance,
    //         null,
    //     );
}
