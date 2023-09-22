const std = @import("std");
const consts = @import("consts.zig");
const transformations = @import("transformations.zig");

/// Performs key expansion on the given cipher key.
/// Note that the function only accepts a 128-bit cipher key,
/// and the caller is expected to ensure correct padding before calling this function.
pub fn keyExpansion(cipher_key: [16]u8) [176]u8 {
    var schedule: [176]u8 = undefined;

    // fill up the first 16 bytes with the key
    for (0..4) |i| {
        for (0..4) |j| {
            schedule[i * 4 + j] = cipher_key[i * 4 + j];
        }
    }

    // perform key expansions for the remaining 160 bytes
    for (4..44) |i| {
        // copy previous word
        var temp = [4]u8{ 0, 0, 0, 0 };
        for (0..4) |j| {
            temp[j] = schedule[i * 4 - (4 - j)];
        }
        if (i % 4 == 0) {
            rotWord(&temp);
            subWord(&temp);
            temp[0] ^= consts.rcon[(i / 4) - 1];
        }
        for (0..4) |j| {
            schedule[i * 4 + j] = schedule[i * 4 - 16 + j] ^ temp[j];
        }
    }

    return schedule;
}

fn subWord(in: []u8) void {
    for (0..4) |i| {
        in[i] = transformations.subByte(in[i], consts.s_box);
    }
}

fn rotWord(in: []u8) void {
    const carry = in[0];
    in[0] = in[1];
    in[1] = in[2];
    in[2] = in[3];
    in[3] = carry;
}
