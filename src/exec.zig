const std = @import("std");
const child_process = std.child_process.ChildProcess;
const alloc = std.mem.Allocator;

pub fn main() void {
    const argv = [_][]const u8{ "ls", "./" };

    const proc = try child_process.run(.{
        .allocator = alloc,
        .argv = &argv,
    });

    // on success, we own the output streams
    defer alloc.free(proc.stdout);
    defer alloc.free(proc.stderr);

    std.debug.print("{s}", .{proc.stdout});

    const term = proc.term;
    _ = term;
}
