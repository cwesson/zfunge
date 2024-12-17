//! @file ip.zig
//! @author Conlan Wesson
//! Instruction pointer for zFunge.

const std = @import("std");
const expect = @import("std").testing.expect;
const funge = struct {
    usingnamespace @import("vector.zig");
    usingnamespace @import("field.zig");
};

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
        return IP{
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
        if (self.pos.x > max.x) {
            self.pos.x = 0;
        }
        if (self.pos.y > max.y) {
            self.pos.y = 0;
        }
        // Check wrapping off negative edge
        if (self.pos.x < 0) {
            self.pos.x = max.x;
        }
        if (self.pos.y < 0) {
            self.pos.y = max.y;
        }
    }

    /// Get the current position.
    /// @return Current position.
    pub fn position(self: IP) funge.Vector {
        return self.pos;
    }

    test "warp +x" {
        var field = try funge.Field.init();
        try field.put(.{ .x = 79, .y = 24 }, 'a');
        var ip = IP.init(.{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, &field);

        var i: i64 = 0;
        while (i < 80) : (i += 1) {
            const pos = ip.position();
            try expect(pos.x == i);
            try expect(pos.y == 0);
            ip.next();
        }

        // Make sure it wrapped
        const pos = ip.position();
        try expect(pos.x == 0);
        try expect(pos.y == 0);
    }

    test "warp +y" {
        var field = try funge.Field.init();
        try field.put(.{ .x = 79, .y = 24 }, 'a');
        var ip = IP.init(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, &field);

        var i: i64 = 0;
        while (i < 25) : (i += 1) {
            const pos = ip.position();
            try expect(pos.x == 0);
            try expect(pos.y == i);
            ip.next();
        }

        // Make sure it wrapped
        const pos = ip.position();
        try expect(pos.x == 0);
        try expect(pos.y == 0);
    }

    test "warp -x" {
        var field = try funge.Field.init();
        try field.put(.{ .x = 79, .y = 24 }, 'a');
        var ip = IP.init(.{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, &field);

        var i: i64 = 0;
        while (i < 80) : (i += 1) {
            ip.next();
            const pos = ip.position();
            try expect(pos.x == 80 - i - 1);
            try expect(pos.y == 0);
        }
    }

    test "warp -y" {
        var field = try funge.Field.init();
        try field.put(.{ .x = 79, .y = 24 }, 'a');
        var ip = IP.init(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, &field);

        var i: i64 = 0;
        while (i < 25) : (i += 1) {
            ip.next();
            const pos = ip.position();
            try expect(pos.x == 0);
            try expect(pos.y == 25 - i - 1);
        }
    }
};
