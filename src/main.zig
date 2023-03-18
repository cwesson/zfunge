//! @file main.zig
//! @author Conlan Wesson
//! Basic Befunge interpretter written in Zig.

const std = @import("std");
const expect = @import("std").testing.expect;
const print = std.debug.print;
const funge = struct {
    usingnamespace @import("vector.zig");
    usingnamespace @import("field.zig");
    usingnamespace @import("stack.zig");
};

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

/// Funge error type
const FungeError = error {
    /// Invalid instruction encountered
    InvalidInstructionError,
};

/// Parse a Funge file.
/// @param filename Path of the file.
/// @return Field for the Funge program.
fn parse(filename: []u8) !funge.Field {
    const file = try std.fs.cwd().openFile(filename, .{.read=true, .write=false});
    defer file.close();

    var f = try funge.Field.init();
    const reader = file.reader();
    var x: i64 = 0;
    var y: i64 = 0;
    var eol = false;
    while(reader.readByte()) |byte| {
        if(byte == '\n' or byte == '\r'){
            if(!eol){
                y += 1;
                x = 0;
                eol = true;
            }
        }else{
            try f.put(.{.x=x, .y=y}, byte);
            x += 1;
            eol = false;
        }
    } else |err| {
        switch (err) {
            error.EndOfStream => return f,
            else => |e| return e,
        }
    }
}

/// Run a Funge program.
/// @param field Field of the Funge program.
/// @return Exit code from the Funge program.
fn run(field: funge.Field) !u8 {
    // Prepare IP
    var pos: funge.Vector = .{.x=0, .y=0};
    var dir: funge.Vector = .{.x=1, .y=0};
    // Prepare stack
    var stack = try funge.Stack.init();

    // Run the program
    while(true) {
        const i = field.get(pos);
        switch(i) {
            ' ' => {},

            // Numbers
            '0'...'9' => try stack.push(i - '0'),

            // Arithmetic
            '+' => {
                const a = stack.pop();
                const b = stack.pop();
                try stack.push(b+a);
            },
            '-' => {
                const a = stack.pop();
                const b = stack.pop();
                try stack.push(b-a);
            },
            '*' => {
                const a = stack.pop();
                const b = stack.pop();
                try stack.push(b*a);
            },
            '/' => {
                const a = stack.pop();
                const b = stack.pop();
                try stack.push(@divTrunc(b, a));
            },
            '%' => {
                const a = stack.pop();
                const b = stack.pop();
                try stack.push(@rem(b, a));
            },

            // Output
            '.' => {
                const a = stack.pop();
                print("{d} ", .{a});
            },

            // Stack manipulation
            ':' => {
                const a = stack.pop();
                try stack.push(a);
                try stack.push(a);
            },

            // Flow control
            '>' => {
                dir.x = 1;
                dir.y = 0;
            },
            '<' => {
                dir.x = -1;
                dir.y = 0;
            },
            'v' => {
                dir.x = 0;
                dir.y = 1;
            },
            '^' => {
                dir.x = 0;
                dir.y = -1;
            },

            // Exit
            '@' => return 0,

            // Error
            else => return FungeError.InvalidInstructionError,
        }

        // Increment IP
        pos.x += dir.x;
        pos.y += dir.y;
        const max = field.bound();
        if(pos.x > max.x){
            pos.x = 0;
        }
        if(pos.y > max.y){
            pos.y = 0;
        }
        if(pos.x < 0){
            pos.x = max.x;
        }
        if(pos.y < 0){
            pos.y = max.y;
        }
    }
}

/// Main for zFunge
/// @return Exit code from Funge program
pub fn main() !u8 {
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    try expect(args.len >= 2);

    var f = try parse(args[1]);
    return run(f);
}
