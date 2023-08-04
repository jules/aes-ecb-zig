const std = @import("std");
const transformations = @import("transformations.zig");

const state_size: usize = 16;

const State = struct {
    mat: [state_size]u8,

    pub fn init(in: [state_size]u8) State {
        var self = State{
            .mat = [state_size]u8{
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
            },
        };

        self.mat = in;
        return self;
    }

    pub fn addRoundKey(self: State, key: [state_size]u8) void {
        for (self.mat, key, 0..) |state, k, i| {
            self.mat[i] = state ^ k;
        }
    }

    pub fn subBytes(self: State) void {
        for (self.mat, 0..) |byte, i| {
            self.mat[i] = transformations.subByte(byte);
        }
    }

    pub fn shiftRows(self: State) void {
        var offset: usize = 4;
        for (1..4) |i| {
            var shift: [4]u8 = undefined;
            // TODO: lol, lmao
            for (0..4) |j| {
                shift[j] = self.mat[i + offset * i + j * 4 % state_size];
            }

            for (0..4) |j| {
                self.mat[i + j * offset] = shift[j];
            }
        }
    }

    pub fn mixColumns(self: State) void {
        const muls_1 = @Vector(4, u8){ 2, 3, 1, 1 };
        const muls_2 = @Vector(4, u8){ 1, 2, 3, 1 };
        const muls_3 = @Vector(4, u8){ 1, 1, 2, 3 };
        const muls_4 = @Vector(4, u8){ 3, 1, 1, 2 };
        for (0..4) |i| {
            const state_col: @Vector(4, u8) = self.mat[i * 4 .. i * 4 + 4];
            self.mat[i * 4] = row_mul_into_xor(state_col, muls_1);
            self.mat[i * 4] = row_mul_into_xor(state_col, muls_2);
            self.mat[i * 4] = row_mul_into_xor(state_col, muls_3);
            self.mat[i * 4] = row_mul_into_xor(state_col, muls_4);
        }
    }
};

fn row_mul_into_xor(state: @Vector(4, u8), muls: @Vector(4, u8)) u8 {
    const result_col = state * muls;
    return result_col[0] ^ result_col[1] ^ result_col[2] ^ result_col[3];
}
