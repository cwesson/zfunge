//! @file field.zig
//! @author Conlan Wesson
//! Field for zFunge.

const std = @import("std");
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
        return Field {
            .map = std.AutoHashMap(vector.Vector, i64).init(gpa),
            .max = .{.x=0, .y=0},
        };
    }

    /// Put a value on the field.
    /// @param pos Position to put to.
    /// @param val Value to put.
    pub fn put(self: *Field, pos: vector.Vector, val: i64) !void {
        try self.map.put(pos, val);
        if(pos.x > self.max.x){
            self.max.x = pos.x;
        }
        if(pos.y > self.max.y){
            self.max.y = pos.y;
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
};
