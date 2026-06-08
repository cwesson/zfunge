//! @file stack.zig
//! @author Conlan Wesson
//! Stack for zFunge.

const std = @import("std");
const expect = @import("std").testing.expect;
const vector = @import("vector.zig");

/// Stack type for Funge stacks.
pub const Stack = struct {
    /// Values on the stack.
    alloc: std.mem.Allocator,
    list: std.ArrayList(i64),

    /// Create a new stack.
    /// @param alloc Allocator to store the stack.
    pub fn init(alloc: std.mem.Allocator) !Stack {
        return Stack{
            .alloc = alloc,
            .list = try std.ArrayList(i64).initCapacity(alloc, 128),
        };
    }

    /// Destroy the stack.
    pub fn deinit(self: *Stack) void {
        self.list.deinit(self.alloc);
    }

    /// Push a value on to the stack.
    /// @param val Value to push.
    pub fn push(self: *Stack, val: i64) !void {
        try self.list.append(self.alloc, val);
    }

    /// Pop a value off the stack.
    /// @param Value from the top of the stack.
    pub fn pop(self: *Stack) i64 {
        return self.list.pop() orelse 0;
    }

    test "simple push/pop" {
        var s = try Stack.init(std.testing.allocator);
        defer s.deinit();

        // empty stack should pop 0
        try expect(s.pop() == 0);

        try s.push(1);
        try s.push(2);
        try expect(s.pop() == 2);
        try s.push(3);
        try s.push(4);
        try expect(s.pop() == 4);
        try expect(s.pop() == 3);
        try expect(s.pop() == 1);

        // empty stack should pop 0
        try expect(s.pop() == 0);
        try expect(s.pop() == 0);
        try expect(s.pop() == 0);
    }
};
