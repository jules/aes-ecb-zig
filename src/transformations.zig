const std = @import("std");

/// Performs a substitution for the given byte and the given s-box.
pub fn subByte(in: u8, s_box: [256]u8) u8 {
    const upper = in >> 4;
    const lower = in & 0b00001111;
    return s_box[16 * upper + lower];
}
