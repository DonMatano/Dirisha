const win32 = @import("../win32/win32.zig");
const std = @import("std");
const DebugAllocator = std.heap.DebugAllocator;
const w = std.os.windows;
const win32Types = win32.types;

fn wndProc(handle: win32Types.Handle, message: u32, wParam: usize, lParam: isize) isize {
    _ = handle;
    _ = message;
    _ = wParam;
    _ = lParam;
    return 0;
}

pub fn run() !void {
    const class_name = "Sample Class Window";
    const instance = try win32Types.GetCurrentHandleInstance();
    var debug_alloc = DebugAllocator(.{}).init;
    const allocator = debug_alloc.allocator();
    defer std.debug.assert(debug_alloc.deinit() == .ok);

    const wc: win32Types.WinClass = .{
        .win_proc = @constCast(&wndProc),
        .instance = instance,
        .class_name = class_name,
    };
    _ = try win32Types.RegisterClass(allocator, wc);
    std.debug.print("instance {}\n ", .{instance});

    const hwnd = try win32.types.CreateWindow(allocator, .{
        .class_name = class_name,
        .window_name = "Learn to program",
        .instance = instance,
    });
    _ = win32Types.showWindow(hwnd, .show);
}
