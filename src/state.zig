const std = @import("std");
const consts = @import("consts.zig");
const transformations = @import("transformations.zig");

/// AES state size is always 16 bytes.
pub const state_size: usize = 16;

/// Represents internal cipher state.
pub const State = struct {
    mat: [state_size]u8,

    /// Creates a State object from the given input bytes.
    /// This function expects the caller to have padded the input properly.
    pub fn init(in: []const u8) State {
        var self = State{
            .mat = [state_size]u8{
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
            },
        };

        for (in, 0..) |byte, i| {
            self.mat[i] = byte;
        }
        return self;
    }

    pub fn addRoundKey(self: *State, key: []const u8) void {
        for (self.mat, key, 0..) |state, k, i| {
            self.mat[i] = state ^ k;
        }
    }

    pub fn subBytes(self: *State) void {
        for (self.mat, 0..) |byte, i| {
            self.mat[i] = transformations.subByte(byte);
        }
    }

    pub fn shiftRows(self: *State) void {
        var offset: usize = 4;
        for (1..4) |i| {
            var shift: [4]u8 = undefined;
            // TODO: lol, lmao
            for (0..4) |j| {
                shift[j] = self.mat[(i + offset * i + j * 4) % state_size];
            }

            for (0..4) |j| {
                self.mat[i + j * offset] = shift[j];
            }
        }
    }

    pub fn mixColumns(self: *State) void {
        const muls_1 = @Vector(4, u8){ 2, 3, 1, 1 };
        const muls_2 = @Vector(4, u8){ 1, 2, 3, 1 };
        const muls_3 = @Vector(4, u8){ 1, 1, 2, 3 };
        const muls_4 = @Vector(4, u8){ 3, 1, 1, 2 };
        const slice: []const u8 = &self.mat;
        for (0..4) |i| {
            const state_col: @Vector(4, u8) = slice[i * 4 ..][0..4].*;
            self.mat[i * 4] = row_mul_into_xor(state_col, muls_1);
            self.mat[i * 4 + 1] = row_mul_into_xor(state_col, muls_2);
            self.mat[i * 4 + 2] = row_mul_into_xor(state_col, muls_3);
            self.mat[i * 4 + 3] = row_mul_into_xor(state_col, muls_4);
        }
    }

    pub fn invSubBytes(self: *State) void {
        for (self.mat, 0..) |byte, i| {
            const upper = byte >> 4;
            const lower = byte & 0xf;
            self.mat[i] = consts.inv_s_box[16 * upper + lower];
        }
    }

    pub fn invShiftRows(self: *State) void {
        var offset: usize = 4;
        for (1..4) |i| {
            var shift: [4]u8 = undefined;
            for (0..4) |j| {
                shift[j] = self.mat[(i + offset * (4 - i) + j * 4) % state_size];
            }

            for (0..4) |j| {
                self.mat[i + j * offset] = shift[j];
            }
        }
    }

    pub fn invMixColumns(self: *State) void {
        const muls_1 = @Vector(4, u8){ 0xe, 0xb, 0xd, 0x9 };
        const muls_2 = @Vector(4, u8){ 0x9, 0xe, 0xb, 0xd };
        const muls_3 = @Vector(4, u8){ 0xd, 0x9, 0xe, 0xb };
        const muls_4 = @Vector(4, u8){ 0xb, 0xd, 0x9, 0xe };
        const slice: []const u8 = &self.mat;
        for (0..4) |i| {
            const state_col: @Vector(4, u8) = slice[i * 4 ..][0..4].*;
            self.mat[i * 4] = row_mul_into_xor(state_col, muls_1);
            self.mat[i * 4 + 1] = row_mul_into_xor(state_col, muls_2);
            self.mat[i * 4 + 2] = row_mul_into_xor(state_col, muls_3);
            self.mat[i * 4 + 3] = row_mul_into_xor(state_col, muls_4);
        }
    }
};

fn row_mul_into_xor(state: @Vector(4, u8), muls: @Vector(4, u8)) u8 {
    const result_col = @mulWithOverflow(state, muls);
    return result_col[0][0] ^ result_col[0][1] ^ result_col[0][2] ^ result_col[0][3];
}
