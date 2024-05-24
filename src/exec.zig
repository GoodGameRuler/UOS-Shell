const std = @import("std");
const child_process = std.ChildProcess;

pub const ExecCommandError = error{ CommandNotFound, OutOfMemeory, ExitError, UnknownError };

pub fn execCommand(exec_str: [2][]const u8, commands: std.StringHashMap([]const u8), alloc: std.mem.Allocator) ExecCommandError!void {
    const exec_str_command: []const u8 = exec_str[0];
    const exit_string = "exit";

    if (exec_str.len == 0 or exec_str[0].len == 0) {
        return ExecCommandError.CommandNotFound;
    }

    if (std.mem.eql(u8, exit_string, exec_str[0])) {
        return ExecCommandError.ExitError;
    }

    const path_adjusted_command: []const u8 = commands.get(exec_str_command) orelse return ExecCommandError.CommandNotFound;

    const padjusted_exec_str = [_][]const u8{ path_adjusted_command, exec_str[1] };

    const proc = child_process.run(.{
        .allocator = alloc,
        .argv = &padjusted_exec_str,
    }) catch {
        return ExecCommandError.UnknownError;
    };

    // on success, we own the output streams
    defer alloc.free(proc.stdout);
    defer alloc.free(proc.stderr);

    std.debug.print("{s}", .{proc.stdout});
    std.debug.print("{s}", .{proc.stderr});

    const term = proc.term;
    _ = term;
}
