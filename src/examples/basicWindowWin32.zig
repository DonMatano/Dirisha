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
    const class_name = "Sample Class Window";
    const instance = win32Types.GetCurrentHandleInstance();

    const wc: win32Types.WinClass = .{
        .win_proc = wndProc,
        .instance = instance,
        .class_name = class_name,
    };
    const hwnd = win32.types.CreateWindow(.{
        .class_name = class_name,
        .window_name = "Learn to program",
        .instance = instance,
    });
}
