//! @file stack.zig
//! @author Conlan Wesson
//! Stack for zFunge.

const std = @import("std");
const expect = @import("std").testing.expect;
const vector = @import("vector.zig");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = general_purpose_allocator.allocator();

/// Stack type for Funge stacks.
pub const Stack = struct {
    /// Values on the stack.
    list: std.ArrayList(i64),

    /// Create a new stack.
    pub fn init() !Stack {
        return Stack{
            .list = std.ArrayList(i64).init(gpa),
        };
    }

    /// Push a value on to the stack.
    /// @param val Value to push.
    pub fn push(self: *Stack, val: i64) !void {
        try self.list.append(val);
    }

    /// Pop a value off the stack.
    /// @param Value from the top of the stack.
    pub fn pop(self: *Stack) i64 {
        return self.list.popOrNull() orelse 0;
    }

    test "simple push/pop" {
        var s = try Stack.init();

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
