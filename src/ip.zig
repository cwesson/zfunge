//! @file ip.zig
//! @author Conlan Wesson
//! Instruction pointer for zFunge.

const std = @import("std");
const expect = @import("std").testing.expect;
const funge = struct {
    usingnamespace @import("vector.zig");
    usingnamespace @import("field.zig");
};

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

/// IP type for Funge.
pub const IP = struct {
    /// Position of the IP.
    pos: funge.Vector,
    /// Direction of the IP.
    dir: funge.Vector,
    /// Field the IP is on.
    field: *funge.Field,

    /// Create a new IP.
    pub fn init(pos: funge.Vector, dir: funge.Vector, field: *funge.Field) IP {
        return IP {
            .pos = pos,
            .dir = dir,
            .field = field,
        };
    }

    /// Increment the IP.
    pub fn next(self: *IP) void {
        self.pos.x += self.dir.x;
        self.pos.y += self.dir.y;
        // Check wrapping off positive edge
        const max = self.field.bound();
        if(self.pos.x > max.x){
            self.pos.x = 0;
        }
        if(self.pos.y > max.y){
            self.pos.y = 0;
        }
        // Check wrapping off negative edge
        if(self.pos.x < 0){
            self.pos.x = max.x;
        }
        if(self.pos.y < 0){
            self.pos.y = max.y;
        }
    }

    /// Get the current position.
    pub fn position(self: IP) funge.Vector {
        return self.pos;
    }
};
