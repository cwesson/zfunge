//! @file main.zig
//! @author Conlan Wesson
//! Basic Befunge interpreter written in Zig.

const std = @import("std");
const expect = @import("std").testing.expect;
const print = std.debug.print;
const funge = struct {
    usingnamespace @import("vector.zig");
    usingnamespace @import("field.zig");
    usingnamespace @import("stack.zig");
    usingnamespace @import("ip.zig");
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
fn run(field: *funge.Field) !u8 {
    // Prepare IP
    var ip = funge.IP.init(.{.x=0, .y=0}, .{.x=1, .y=0}, field);
    // Prepare stack
    var stack = try funge.Stack.init();
    var string_mode = false;

    // Run the program
    while(true) {
        // Get next instruction
        const i = field.get(ip.position());

        // Execute instruction
        if(string_mode){
            if(i != '"'){
                try stack.push(i);
            }else{
                string_mode = false;
            }
        }else{
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
                '!' => {
                    const a = stack.pop();
                    if(a != 0){
                        try stack.push(0);
                    }else{
                        try stack.push(1);
                    }
                },
                '`' => {
                    const a = stack.pop();
                    const b = stack.pop();
                    if(b > a){
                        try stack.push(1);
                    }else{
                        try stack.push(0);
                    }
                },

                // Output
                '.' => {
                    const a = stack.pop();
                    print("{d} ", .{a});
                },
                ',' => {
                    const a = stack.pop();
                    print("{c}", .{@intCast(u8, a)});
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
                // Conditionals
                '_' => {
                    const a = stack.pop();
                    if(a != 0){
                        ip.dir.x = -1;
                    }else{
                        ip.dir.x = 1;
                    }
                    ip.dir.y = 0;
                },
                '|' => {
                    const a = stack.pop();
                    if(a != 0){
                        ip.dir.y = -1;
                    }else{
                        ip.dir.y = 1;
                    }
                    ip.dir.x = 0;
                },

                // Self-modifying
                'g' => {
                    const y = stack.pop();
                    const x = stack.pop();
                    try stack.push(field.get(.{.x=x, .y=y}));
                },
                'p' => {
                    const y = stack.pop();
                    const x = stack.pop();
                    const v = stack.pop();
                    try field.put(.{.x=x, .y=y}, v);
                },

                // Exit
                '@' => return 0,

                // Error
                else => {
                    print("({}, {}) = {c}", .{ip.pos.x, ip.pos.y, @intCast(u8,i)});
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
pub fn main() !u8 {
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    try expect(args.len >= 2);

    var f = try parse(args[1]);
    return run(&f);
}
