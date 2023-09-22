const std = @import("std");
const consts = @import("consts.zig");

pub fn subByte(in: u8) u8 {
    const upper = in >> 4;
    const lower = in & 0b00001111;
    return consts.s_box[16 * upper + lower];
}
