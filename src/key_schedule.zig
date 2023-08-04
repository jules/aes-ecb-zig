const std = @import("std");
const consts = @import("consts.zig");
const transformations = @import("transformations.zig");

/// Performs key expansion on the given cipher key.
/// Note that the function only accepts a 128-bit cipher key,
/// and the caller is expected to ensure correct padding before calling this function.
pub fn keyExpansion(cipher_key: [16]u8) []u8 {
    var schedule: [176]u8 = undefined;

    // fill up the first 16 bytes with the key
    for (0..4) |i| {
        for (0..4) |j| {
            schedule[j] = cipher_key[i * 4 + j];
        }
    }

    // perform key expansions for the remaining 160 bytes
    for (4..44) |i| {
        var temp = schedule[i * 4 - 4 .. i * 4];
        if (i % 4 == 0) temp = subWord(rotWord(temp)) ^ consts.rcon[(i / 4) / 4];
        for (0..4) |j| {
            schedule[i + j] = schedule[i * 4 - 4 + j] ^ temp;
        }
    }

    return &schedule;
}

fn subWord(in: []u8) []u8 {
    var out: [4]u8 = undefined;
    for (0..4) |i| {
        out[i] = transformations.subByte(in[i]);
    }
    return &out;
}

fn rotWord(in: []u8) []u8 {
    var out: [4]u8 = undefined;
    out[0] = in[1];
    out[1] = in[2];
    out[2] = in[3];
    out[3] = in[0];
    return &out;
}
