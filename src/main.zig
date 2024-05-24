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

    var env_map = std.process.EnvMap.init(alloc);
    defer env_map.deinit();

    try commands.put("PATH", "/usr/bin:/usr/local/bin");

    try stdout.print("{s} Welcome to {s}!{s}\n", .{ RED, SHELL_NAME, RESET });

    var exit_cond = false;
    // var in_buffer: [10]u8 = undefined;

    while (!exit_cond) {
        try stdout.print("{s} \n", .{SHELL_NAME_C});
        try stdout.print("> ", .{});

        // var input_vargs: []u8 = stdin.readUntilDelimiterOrEofAlloc(io_allocator, '\n', 100) catch |err| switch (err) {
        //     error.StreamTooLong => {
        //         try stdout.print("Stream Too Long Allocation Error 1!\n", .{});
        //         return;
        //     },
        //     else => {
        //         try stdout.print("Unknown Allocation Error 1!\n", .{});
        //         return;
        //     },
        // } orelse "";
        //
        // defer io_allocator.free(input_vargs);
        //
        // const input_command = parseCommand(input_vargs, io_allocator);
        //
        // defer if (input_command) |i| io_allocator.free(i);
        //
        // var exec_str: [2][]const u8 = undefined;
        //
        // if (input_command) |command| {
        //     exec_str = [2][]const u8{ command, input_vargs[(command.len + 1)..] };
        // } else {
        //     exec_str = [2][]const u8{ input_vargs[0..], "" };
        // }

        const exec_str = readInput(io_allocator) orelse continue;
        std.debug.print("'{s}'\n", .{exec_str});

        exec.execCommand(exec_str, commands, env_map, alloc) catch |err| switch (err) {
            ExecCommandError.ExitError => {
                exit_cond = true;
            },
            ExecCommandError.CommandNotFound => {
                try stdout.print("Command '{s}' not Found!\n", .{exec_str[0]});
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

fn readInput(alloc: std.mem.Allocator) ?[][]u8 {
    var continue_input = true;

    var tokenised_input = std.ArrayList([]u8).init(alloc);
    var tokenised_word = std.ArrayList(u8).init(alloc);

    defer tokenised_word.deinit();
    defer tokenised_input.deinit();

    while (continue_input) {
        var input_str: []u8 = stdin.readUntilDelimiterOrEofAlloc(alloc, '\n', 100) catch |err| switch (err) {
            error.StreamTooLong => {
                stdout.print("Stream Too Long Allocation Error 1!\n", .{}) catch {
                    std.debug.print("Error printing not working 1\n", .{});
                };
                return null;
            },
            else => {
                stdout.print("Unknown Allocation Error 1!\n", .{}) catch {
                    std.debug.print("Error printing not working 1\n", .{});
                };

                return null;
            },
        } orelse "";

        _ = &input_str;

        var last_char: ?u8 = null;
        var last_backslash = false;

        for (input_str) |char| {
            if (char == ' ' or char == '\t') {

                // Meaning we just finished a word
                if (last_char != null) {
                    tokenised_input.append(tokenised_word.toOwnedSlice() catch "") catch {
                        return null;
                    };
                }

                last_char = null;
            } else if (char == '\\' and (last_char == null or last_char == '\\')) {
                last_char = '\\';
                last_backslash = true;
            } else {
                if (last_backslash) {
                    tokenised_word.append(last_char.?) catch {
                        return null;
                    };

                    last_backslash = false;
                }

                last_char = char;

                tokenised_word.append(char) catch return null;
            }
        } else {
            if (tokenised_word.toOwnedSlice() catch null) |str| {
                tokenised_input.append(str) catch {
                    return null;
                };
            }
        }

        defer alloc.free(input_str);

        if (last_char != '\\') {
            continue_input = false;
        }
    }

    return tokenised_input.toOwnedSlice() catch null;
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
