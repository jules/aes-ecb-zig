const std = @import("std");
const consts = @import("consts.zig");
const transformations = @import("transformations.zig");

// Shifted polynomial constants for mixColumns.
const muls_1 = [4]u8{ 2, 3, 1, 1 };
const muls_2 = [4]u8{ 1, 2, 3, 1 };
const muls_3 = [4]u8{ 1, 1, 2, 3 };
const muls_4 = [4]u8{ 3, 1, 1, 2 };

// Inverse shifted polynomial constants for invMixColumns.
const inv_muls_1 = [4]u8{ 0xe, 0xb, 0xd, 0x9 };
const inv_muls_2 = [4]u8{ 0x9, 0xe, 0xb, 0xd };
const inv_muls_3 = [4]u8{ 0xd, 0x9, 0xe, 0xb };
const inv_muls_4 = [4]u8{ 0xb, 0xd, 0x9, 0xe };

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

    /// Does an elementwise XOR with a given set of key bytes.
    pub fn addRoundKey(self: *State, key: []const u8) void {
        for (self.mat, key, 0..) |state, k, i| {
            self.mat[i] = state ^ k;
        }
    }

    /// Performs the s-box for the entire cipher state.
    pub fn subBytes(self: *State) void {
        for (self.mat, 0..) |byte, i| {
            self.mat[i] = transformations.subByte(byte, consts.s_box);
        }
    }

    /// Shifts each of the matrix rows left by rowIndex.
    /// E.g, first row shifts by 0, second row by 1, etc...
    pub fn shiftRows(self: *State) void {
        var offset: usize = 4;
        for (1..4) |i| {
            var shift: [4]u8 = undefined;
            // TODO: lol, lmao
            for (0..4) |j| {
                shift[j] = self.mat[(i + (offset * i) + (j * 4)) % state_size];
            }

            for (0..4) |j| {
                self.mat[i + j * offset] = shift[j];
            }
        }
    }

    /// Interprets each matrix column as a 4-term polynomial over GF(2^8) and performs
    /// a multiplication with 3x^3 + x^2 + x + 2 modulo x^4 + 1.
    pub fn mixColumns(self: *State) void {
        self.polyMult(muls_1, muls_2, muls_3, muls_4);
    }

    /// Performs an inverted s-box for the whole cipher state.
    pub fn invSubBytes(self: *State) void {
        for (self.mat, 0..) |byte, i| {
            self.mat[i] = transformations.subByte(byte, consts.inv_s_box);
        }
    }

    /// Shifts each of the matrix rows right by rowIndex.
    /// E.g, first row shifts by 0, second row by 1, etc...
    pub fn invShiftRows(self: *State) void {
        var offset: usize = 4;
        for (1..4) |i| {
            var shift: [4]u8 = undefined;
            for (0..4) |j| {
                shift[j] = self.mat[(i + (offset * (4 - i)) + (j * 4)) % state_size];
            }

            for (0..4) |j| {
                self.mat[i + j * offset] = shift[j];
            }
        }
    }

    /// Interprets each matrix column as a 4-term polynomial over GF(2^8) and performs
    /// a multiplication with 11^3 + 13x^2 + 9x + 14 modulo x^4 + 1.
    pub fn invMixColumns(self: *State) void {
        self.polyMult(inv_muls_1, inv_muls_2, inv_muls_3, inv_muls_4);
    }

    fn polyMult(self: *State, m_1: [4]u8, m_2: [4]u8, m_3: [4]u8, m_4: [4]u8) void {
        const slice: []const u8 = &self.mat;
        for (0..4) |i| {
            const state_col: [4]u8 = slice[i * 4 ..][0..4].*;
            self.mat[i * 4] = row_mul_into_xor(state_col, m_1);
            self.mat[i * 4 + 1] = row_mul_into_xor(state_col, m_2);
            self.mat[i * 4 + 2] = row_mul_into_xor(state_col, m_3);
            self.mat[i * 4 + 3] = row_mul_into_xor(state_col, m_4);
        }
    }
};

fn row_mul_into_xor(state: [4]u8, muls: [4]u8) u8 {
    return multiply(state[0], muls[0]) ^ multiply(state[1], muls[1]) ^ multiply(state[2], muls[2]) ^ multiply(state[3], muls[3]);
}

fn multiply(num: u8, mul: u8) u8 {
    // since we have constant multiplication terms and multiplication isn't straightforward,
    // we instead just switch on different constants and apply the right arithmetic.
    return switch (mul) {
        0x01 => num,
        0x02 => mul_by_2(num),
        0x03 => mul_by_2(num) ^ num,
        0x09 => mul_by_2(mul_by_2(mul_by_2(num))) ^ num,
        0x0b => mul_by_2(mul_by_2(mul_by_2(num))) ^ mul_by_2(num) ^ num,
        0x0d => mul_by_2(mul_by_2(mul_by_2(num))) ^ mul_by_2(mul_by_2(num)) ^ num,
        0x0e => mul_by_2(mul_by_2(mul_by_2(num))) ^ mul_by_2(mul_by_2(num)) ^ mul_by_2(num),
        else => @panic("unexpected constant"),
    };
}

// GF(2^8) multiplication by 2
fn mul_by_2(num: u8) u8 {
    var shifted_num = num << 1;
    // if we overflow, we need to reduce mod x^8 + x^4 + x^3 + x + 1
    if (num & 0b10000000 == 0b10000000) {
        // since x^8 already gets chopped off from the bitshift, we can just XOR by 0b00011011
        shifted_num ^= 0b00011011;
    }

    return shifted_num;
}
