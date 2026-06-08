//! @file main.zig
//! @author Conlan Wesson
//! Basic Befunge interpreter written in Zig.

const std = @import("std");
const expect = @import("std").testing.expect;
const fungevector = @import("vector.zig");
const fungefield = @import("field.zig");
const fungestack = @import("stack.zig");
const fungeip = @import("ip.zig");

/// Funge error type.
const FungeError = error{
    /// Invalid instruction encountered.
    InvalidInstructionError,
};

/// Parse a Funge file.
/// @param alloc Allocator to store the Field.
/// @param io Io to use.
/// @param filename Path of the file.
/// @return Field for the Funge program.
fn parse(alloc: std.mem.Allocator, io: std.Io, filename: []const u8) !fungefield.Field {
    const file = try std.Io.Dir.cwd().openFile(io, filename, .{ .mode = .read_only });
    defer file.close(io);

    var buf: [8]u8 = undefined;
    var field = try fungefield.Field.init(alloc);
    var reader_wrapped = file.reader(io, &buf);
    const reader = &reader_wrapped.interface;
    var x: i64 = 0;
    var y: i64 = 0;
    var eol = false;
    while (reader.takeByte()) |byte| {
        if (byte == '\n' or byte == '\r') {
            if (!eol) {
                y += 1;
                x = 0;
                eol = true;
            }
        } else {
            try field.put(.{ .x = x, .y = y }, byte);
            x += 1;
            eol = false;
        }
    } else |err| {
        switch (err) {
            error.EndOfStream => return field,
            else => |e| return e,
        }
    }
}

/// Run a Funge program.
/// @param alloc Allocator to store the stack.
/// @param io Io to use.
/// @param field Field of the Funge program.
/// @param output Writer to use for printing.
/// @param output Output writer.
/// @param input Input reader.
/// @param errour Error output writer.
/// @return Exit code from the Funge program.
fn run(alloc: std.mem.Allocator, io: std.Io, field: *fungefield.Field, output: *std.Io.Writer, input: *std.Io.Reader, errout: *std.Io.Writer) !u8 {
    var rand = std.Random.DefaultPrng.init(@intCast(std.Io.Clock.real.now(io).toMilliseconds()));
    // Prepare IP
    var ip = fungeip.IP.init(.{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, field);
    // Prepare stack
    var stack = try fungestack.Stack.init(alloc);
    defer stack.deinit();
    var string_mode = false;

    // Run the program
    while (true) {
        // Get next instruction
        const i = field.get(ip.position());

        // Execute instruction
        if (string_mode) {
            if (i != '"') {
                try stack.push(i);
            } else {
                string_mode = false;
            }
        } else {
            switch (i) {
                ' ' => {},

                // Numbers
                '0'...'9' => try stack.push(i - '0'),

                // Arithmetic
                '+' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    try stack.push(b + a);
                },
                '-' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    try stack.push(b - a);
                },
                '*' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    try stack.push(b * a);
                },
                '/' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    if (a == 0) {
                        try stack.push(0);
                    } else {
                        try stack.push(@divTrunc(b, a));
                    }
                },
                '%' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    if (a == 0) {
                        try stack.push(0);
                    } else {
                        try stack.push(@rem(b, a));
                    }
                },
                '!' => {
                    const a = stack.pop();
                    if (a != 0) {
                        try stack.push(0);
                    } else {
                        try stack.push(1);
                    }
                },
                '`' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    if (b > a) {
                        try stack.push(1);
                    } else {
                        try stack.push(0);
                    }
                },

                // Input/Output
                '&' => {
                    var val: i64 = 0;
                    int_in: while (input.takeByte()) |byte| {
                        switch (byte) {
                            '0'...'9' => val = (val * 10) + (byte - '0'),
                            else => break :int_in,
                        }
                    } else |err| {
                        switch (err) {
                            else => {},
                        }
                    }
                    try stack.push(val);
                },
                '~' => {
                    const c = try input.takeByte();
                    try stack.push(@intCast(c));
                },
                '.' => {
                    const a = stack.pop();
                    try output.print("{d} ", .{a});
                    try output.flush();
                },
                ',' => {
                    const a = stack.pop();
                    const c: u8 = @intCast(a);
                    try output.printAsciiChar(c, .{});
                    try output.flush();
                },
                '"' => {
                    string_mode = true;
                },

                // Stack manipulation
                ':' => {
                    const a = stack.pop();
                    try stack.push(a);
                    try stack.push(a);
                },
                '\\' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    try stack.push(a);
                    try stack.push(b);
                },
                '$' => {
                    _ = stack.pop();
                },

                // Flow control
                '>' => {
                    ip.dir.x = 1;
                    ip.dir.y = 0;
                },
                '<' => {
                    ip.dir.x = -1;
                    ip.dir.y = 0;
                },
                'v' => {
                    ip.dir.x = 0;
                    ip.dir.y = 1;
                },
                '^' => {
                    ip.dir.x = 0;
                    ip.dir.y = -1;
                },
                '#' => {
                    ip.next();
                },
                '?' => {
                    switch (rand.random().intRangeAtMost(u8, 0, 3)) {
                        0 => {
                            ip.dir.x = 1;
                            ip.dir.y = 0;
                        },
                        1 => {
                            ip.dir.x = -1;
                            ip.dir.y = 0;
                        },
                        2 => {
                            ip.dir.x = 0;
                            ip.dir.y = 1;
                        },
                        3 => {
                            ip.dir.x = 0;
                            ip.dir.y = -1;
                        },
                        else => unreachable,
                    }
                },
                // Conditionals
                '_' => {
                    const a = stack.pop();
                    if (a != 0) {
                        ip.dir.x = -1;
                    } else {
                        ip.dir.x = 1;
                    }
                    ip.dir.y = 0;
                },
                '|' => {
                    const a = stack.pop();
                    if (a != 0) {
                        ip.dir.y = -1;
                    } else {
                        ip.dir.y = 1;
                    }
                    ip.dir.x = 0;
                },

                // Self-modifying
                'g' => {
                    const y = stack.pop();
                    const x = stack.pop();
                    try stack.push(field.get(.{ .x = x, .y = y }));
                },
                'p' => {
                    const y = stack.pop();
                    const x = stack.pop();
                    const v = stack.pop();
                    try field.put(.{ .x = x, .y = y }, v);
                },

                // Exit
                '@' => return 0,

                // Error
                else => {
                    const c: u8 = @intCast(i);
                    errout.print("({}, {}) = {c}", .{ ip.pos.x, ip.pos.y, c }) catch {};
                    try errout.flush();
                    return FungeError.InvalidInstructionError;
                },
            }
        }

        // Increment IP
        ip.next();
    }
}

/// Main for zFunge
/// @return Exit code from Funge program
pub fn main(init: std.process.Init) !u8 {
    const args = try init.minimal.args.toSlice(init.gpa);
    defer init.gpa.free(args);
    try expect(args.len >= 2);

    var f = try parse(init.gpa, init.io, args[1]);
    defer f.deinit();

    var buf: [16]u8 = undefined;
    var stdout_wrapped = std.Io.File.stdout().writer(init.io, &buf);
    const stdout = &stdout_wrapped.interface;
    var ebuf: [16]u8 = undefined;
    var stderr_wrapped = std.Io.File.stderr().writer(init.io, &ebuf);
    const stderr = &stderr_wrapped.interface;
    var ibuf: [16]u8 = undefined;
    var stdin_wrapped = std.Io.File.stdin().reader(init.io, &ibuf);
    const stdin = &stdin_wrapped.interface;

    return run(init.gpa, init.io, &f, stdout, stdin, stderr);
}

/// Parse and run a test Befunge.
/// @param filename Befunge file to run.
/// @param expected Expected stdout.
fn test_run(filename: []const u8, expected: []const u8) !void {
    var field = try parse(std.testing.allocator, std.testing.io, filename);
    defer field.deinit();

    var output = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer output.deinit();
    var errout = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer errout.deinit();
    var calls: [1]std.testing.Reader.Call = undefined;
    var input = std.testing.Reader.init("", &calls).interface;

    const ret = try run(std.testing.allocator, std.testing.io, &field, &output.writer, &input, &errout.writer);

    try std.testing.expectEqualStrings(expected, output.written());
    try std.testing.expectEqualStrings("", errout.written());
    try expect(ret == 0);
}

test "flow control" {
    try test_run("test/test_flow.bf", "4 3 2 1 0 ");
}

test "arithmetic" {
    try test_run("test/test_arith.bf", "2 3 5 8 13 21 ");
}

test "char output" {
    try test_run("test/test_outchar.bf", "Hello World!");
}

test "conditionals" {
    try test_run("test/test_if.bf", "4 3 2 1 ");
}
