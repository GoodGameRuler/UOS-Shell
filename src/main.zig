const std = @import("std");
const exec = @import("exec.zig");
const ExecCommandError = exec.ExecCommandError;

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

const HELP = "[USHELL] Help - Basic Commands\n  ls\n  cd\n";
const max_input_size = 5000;

pub fn main() anyerror!void {

    // TODO buffer should be remove at some point. It does not make sense to have a general fba.
    var buffer: [5000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fba.allocator();

    var io_buffer: [6000]u8 = undefined;
    var io_fba = std.heap.FixedBufferAllocator.init(&io_buffer);
    const io_allocator = io_fba.allocator();

    var commands = std.StringHashMap([]const u8).init(alloc);
    defer commands.deinit();

    try commands.put("ls", "/usr/bin/ls");

    // TODO cd merely changes an enviorment variable, to successfully execute we need to acess posix env variables.
    try commands.put("cd", "/usr/bin/cd");
    try commands.put("pwd", "/usr/bin/pwd");
    try commands.put("neofetch", "/usr/bin/neofetch");

    try stdout.print("{s} Welcome to {s}!{s}\n", .{ RED, SHELL_NAME, RESET });

    var exit_cond = false;
    // var in_buffer: [10]u8 = undefined;

    while (!exit_cond) {
        try stdout.print("{s} \n", .{SHELL_NAME_C});
        try stdout.print("> ", .{});

        var input_vargs: []u8 = stdin.readUntilDelimiterOrEofAlloc(io_allocator, '\n', 100) catch |err| switch (err) {
            error.StreamTooLong => {
                try stdout.print("Stream Too Long Allocation Error 1!\n", .{});
                return;
            },
            else => {
                try stdout.print("Unknown Allocation Error 1!\n", .{});
                return;
            },
        } orelse "";

        defer io_allocator.free(input_vargs);

        const input_command = parseCommand(input_vargs, io_allocator);

        defer if (input_command) |i| io_allocator.free(i);

        var exec_str: [2][]const u8 = undefined;

        if (input_command) |command| {
            exec_str = [2][]const u8{ command, input_vargs[(command.len + 1)..] };
        } else {
            exec_str = [2][]const u8{ input_vargs[0..], "" };
        }

        exec.execCommand(exec_str, commands, alloc) catch |err| switch (err) {
            ExecCommandError.ExitError => {
                exit_cond = true;
            },
            ExecCommandError.CommandNotFound => {
                try stdout.print("Command '{s}' not Found!\n", .{input_command orelse input_vargs});
            },
            ExecCommandError.OutOfMemeory => {
                try stdout.print("Insufficient Buffer Memory for Result!\n", .{});
            },

            else => {
                try stdout.print("Unhandled Error!\n", .{});
                exit_cond = true;
            },
        };
    }
}

fn parseCommand(input_vargs: []u8, allocator: std.mem.Allocator) ?[]u8 {
    if (input_vargs.len == 0) {
        return null;
    }

    var length: u8 = 0;

    for (input_vargs) |char| {
        if (char == ' ' or char == '\t' or char == '\r' or char == '\n') {
            break;
        }

        length += 1;
    } else {
        return null;
    }

    const return_string = allocator.alloc(u8, length) catch {
        return null;
    };

    std.mem.copyForwards(u8, return_string, input_vargs[0..length]);

    return return_string;
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
