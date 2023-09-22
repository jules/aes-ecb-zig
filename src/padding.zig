const std = @import("std");

/// Pads a key to 16 bytes.
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

/// Pads an input string to a multiple of 16.
pub fn padInput(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const len = if (input.len < 16) 16 else input.len + input.len % 16;

    var padded_input = try allocator.alloc(u8, len);
    for (input, 0..) |byte, i| {
        padded_input[i] = byte;
    }
    for (input.len..len) |i| {
        padded_input[i] = 0;
    }
    return padded_input;
}
