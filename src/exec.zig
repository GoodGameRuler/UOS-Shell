const std = @import("std");
const child_process = std.ChildProcess;

pub fn main() !void {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fba.allocator();

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
