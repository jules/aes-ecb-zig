const std = @import("std");

pub fn padKey(key: []const u8) [16]u8 {
    var out: [16]u8 = undefined;
    for (key, 0..) |byte, i| {
        out[i] = byte;
    }

    for (key.len..16) |i| {
        out[i] = 0;
    }

    return out;
}

pub fn padInput(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len % 16 == 0) {
        return input;
    }

    var padded_input = try allocator.alloc(u8, input.len + input.len % 16);
    for (input, 0..) |byte, i| {
        padded_input[i] = byte;
    }
    return padded_input;
}
