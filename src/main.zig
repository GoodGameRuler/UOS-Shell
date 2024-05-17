const std = @import("std");

// ANSI coloured ouputs
const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const BLUE = "\x1b[34m";
const MAGENTA = "\x1b[35m";
const CYAN = "\x1b[36m";
const RESET = "\x1b[0m";

const SHELL_NAME = "UOShell";
const SHELL_NAME_P = "[UOShell]";

const SHELL_NAME_C = "\x1b[36m[UOShell]\x1b[0m";

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

const COMMANDS = [1][]const u8{"help"};
const EXIT = "exit";

pub fn main() anyerror!void {
    try stdout.print("{s} Welcome to {s}!{s}\n", .{ RED, SHELL_NAME, RESET });

    var exit_cond = false;
    var in_buffer: [10]u8 = undefined;

    while (!exit_cond) {
        try stdout.print("{s} \n", .{SHELL_NAME_C});
        try stdout.print("> ", .{});

        const result = try stdin.readUntilDelimiterOrEof(in_buffer[0..], '\n');

        for (COMMANDS) |command| {
            if (std.mem.eql(u8, result.?, EXIT)) {
                exit_cond = true;
            } else if (std.mem.eql(u8, result.?, command)) {
                std.debug.print("Command!\n", .{});
            } else {
                std.debug.print("Not a Command!\n", .{});
            }
        }
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
