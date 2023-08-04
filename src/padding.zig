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

pub fn padPlaintext(plaintext: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (plaintext.len % 16 == 0) {
        return plaintext;
    }

    var padded_plaintext = try allocator.alloc(u8, plaintext.len + plaintext.len % 16);
    for (plaintext, 0..) |byte, i| {
        padded_plaintext[i] = byte;
    }
    return padded_plaintext;
}
