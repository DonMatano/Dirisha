const std = @import("std");
const Dirisha = @import("Dirisha");
const examples = @import("examples/basicWindowWin32.zig");

pub fn main() !void {
    try examples.run();
}
