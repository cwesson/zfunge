//! @file field.zig
//! @author Conlan Wesson
//! Field for zFunge.

const std = @import("std");
const expect = @import("std").testing.expect;
const vector = @import("vector.zig");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

/// Field type to store the Funge field.
pub const Field = struct {
    /// Map of coordinates to values.
    map: std.AutoHashMap(vector.Vector, i64),
    /// Maximum bounds of the field.
    max: vector.Vector,

    /// Create a new Field.
    pub fn init() !Field {
        return Field{
            .map = std.AutoHashMap(vector.Vector, i64).init(gpa),
            .max = .{ .x = 0, .y = 0 },
        };
    }

    /// Put a value on the field.
    /// @param pos Position to put to.
    /// @param val Value to put.
    pub fn put(self: *Field, pos: vector.Vector, val: i64) !void {
        if (val == ' ') {
            _ = self.map.remove(pos);
            // Find new max
            if (pos.x > self.max.x or pos.y > self.max.y) {
                var max_x: i64 = 0;
                var max_y: i64 = 0;
                var it = self.map.keyIterator();
                while (it.next()) |key| {
                    if (key.x > max_x) {
                        max_x = key.x;
                    }
                    if (key.y > max_y) {
                        max_y = key.y;
                    }
                }
                self.max.x = max_x;
                self.max.y = max_y;
            }
        } else {
            try self.map.put(pos, val);
            if (pos.x > self.max.x) {
                self.max.x = pos.x;
            }
            if (pos.y > self.max.y) {
                self.max.y = pos.y;
            }
        }
    }

    /// Get a value from the field.
    /// @param pos Position to get from.
    /// @return Value at pos.
    pub fn get(self: Field, pos: vector.Vector) i64 {
        return self.map.get(pos) orelse ' ';
    }

    /// Get the maximum bounds of the field.
    /// @return Maximum bounds.
    pub fn bound(self: Field) vector.Vector {
        return self.max;
    }

    test "basic test" {
        var field = try Field.init();

        try field.put(.{ .x = 1, .y = 2 }, 'a');
        try field.put(.{ .x = 3, .y = 4 }, 'b');
        try field.put(.{ .x = 5, .y = 6 }, 'c');
        try field.put(.{ .x = 7, .y = 8 }, 'd');
        try field.put(.{ .x = 9, .y = 0 }, 'e');

        // Unpopulated cells are spaces
        try expect(field.get(.{ .x = 0, .y = 0 }) == ' ');
        try expect(field.get(.{ .x = 0, .y = 9 }) == ' ');

        try expect(field.get(.{ .x = 3, .y = 4 }) == 'b');
        try expect(field.get(.{ .x = 7, .y = 8 }) == 'd');
        try expect(field.get(.{ .x = 5, .y = 6 }) == 'c');
        try expect(field.get(.{ .x = 9, .y = 0 }) == 'e');
        try expect(field.get(.{ .x = 1, .y = 2 }) == 'a');

        // Unpopulated cells are spaces
        try expect(field.get(.{ .x = 1, .y = 1 }) == ' ');
        try expect(field.get(.{ .x = 2, .y = 2 }) == ' ');
    }
};
