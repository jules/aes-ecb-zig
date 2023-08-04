const std = @import("std");
const key_schedule = @import("key_schedule.zig");
const padding = @import("padding.zig");
const State = @import("state.zig").State;

const AesError = error {
    InvalidKeyLength,
}

export fn encrypt(plaintext: []const u8, key: []const u8) ![]u8 {
    if (key.len > 16) {
        return AesError::InvalidKeyLength;
    }

    const padded_key = padding.padKey(key);
    const padded_plaintext = try padding.padPlaintext(plaintext, allocator);
    defer allocator.free(padded_plaintext);

    const keys = key_schedule.keyExpansion(padded_key);

    var ciphertext = try allocator.alloc(u8, padded_plaintext.len);
    const repetitions = padded_plaintext / 16;
    for (0..repetitions) |i| {
        var state = State.init(padded_plaintext[i*16..i*16+16]);
        state.addRoundKey(keys[0..16]);

        for (1..10) |j| {
            state.subBytes();
            state.shiftRows();
            state.mixColumns();
            state.addRoundKey(keys[j*16..j*16+16);
        }

        state.subBytes();
        state.shiftRows();
        state.addRoundKey(keys[keys.len-16..keys.len]);

        ciphertext[i*16..i*16+16] = state;
    }

    return ciphertext;
}

export fn decrypt(ciphertext: []const u8, key: []const u8) ![]u8 {

}
