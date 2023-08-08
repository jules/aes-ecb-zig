const std = @import("std");
const key_schedule = @import("key_schedule.zig");
const padding = @import("padding.zig");
const State = @import("state.zig").State;
const state_size = @import("state.zig").state_size;

const AesError = error{
    InvalidKeyLength,
};

pub fn encrypt(plaintext: []const u8, key: []const u8, allocator: std.mem.Allocator) ![]u8 {
    if (key.len > state_size) {
        return AesError.InvalidKeyLength;
    }

    const padded_key = padding.padKey(key);
    const padded_plaintext = try padding.padPlaintext(plaintext, allocator);
    defer allocator.free(padded_plaintext);

    const keys = key_schedule.keyExpansion(padded_key);

    var ciphertext = try allocator.alloc(u8, padded_plaintext.len);
    const repetitions = padded_plaintext.len / state_size;
    for (0..repetitions) |i| {
        var state = State.init(padded_plaintext[i * state_size .. i * state_size + state_size]);
        state.addRoundKey(keys[0..state_size]);

        for (1..10) |j| {
            state.subBytes();
            state.shiftRows();
            state.mixColumns();
            state.addRoundKey(keys[j * state_size .. j * state_size + state_size]);
        }

        state.subBytes();
        state.shiftRows();
        state.addRoundKey(keys[keys.len - state_size .. keys.len]);

        for (i * state_size..i * state_size + state_size, 0..) |j, k| {
            ciphertext[j] = state.mat[k];
        }
    }

    return ciphertext;
}

pub fn decrypt(ciphertext: []const u8, key: []const u8, allocator: std.mem.Allocator) ![]u8 {
    if (key.len > state_size) {
        return AesError.InvalidKeyLength;
    }

    const padded_key = padding.padKey(key);
    const padded_ciphertext = try padding.padInput(ciphertext, allocator);
    defer allocator.free(padded_ciphertext);

    const keys = key_schedule.keyExpansion(padded_key);

    var plaintext = try allocator.alloc(u8, padded_ciphertext.len);
    const repetitions = padded_ciphertext.len / state_size;
    for (0..repetitions) |i| {
        var state = State.init(padded_ciphertext[i * state_size .. i * state_size + state_size]);

        state.addRoundKey(keys[keys.len - state_size .. keys.len]);

        for (1..10) |j| {
            state.invShiftRows();
            state.invSubBytes();
            const k = 10 - j;
            state.addRoundKey(keys[k * state_size .. k * state_size + state_size]);
            state.invMixColumns();
        }

        state.invShiftRows();
        state.invSubBytes();
        state.addRoundKey(keys[0..state_size]);

        for (i * state_size..i * state_size + state_size, 0..) |j, k| {
            plaintext[j] = state.mat[k];
        }
    }

    return plaintext;
}

const eql = std.mem.eql;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

test "encrypt/decrypt" {
    const ciphertext = try encrypt("text", "hi", test_allocator);
    defer test_allocator.free(ciphertext);
    const plaintext = try decrypt(ciphertext, "hi", test_allocator);
    defer test_allocator.free(plaintext);
    try expect(eql("text", plaintext));
}
