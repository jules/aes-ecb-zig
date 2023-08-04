const std = @import("std");

const State = struct {
    mat: [4][4]u8,

    pub fn init(in: [16]u8) State {
        var self = State{
            .mat = [4][4]u8{
                [4]u8{ 0, 0, 0, 0 },
                [4]u8{ 0, 0, 0, 0 },
                [4]u8{ 0, 0, 0, 0 },
                [4]u8{ 0, 0, 0, 0 },
            },
        };
        for (0..4) |i| {
            self.mat[i] = in[i * 4 .. i * 4 + 4];
        }

        return self;
    }
};
