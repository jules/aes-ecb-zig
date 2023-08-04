const std = @import("std");

const State = struct {
    mat: [16]u8,

    pub fn init(in: [16]u8) State {
        var self = State{
            .mat = [16]u8{
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
            },
        };

        self.mat = in;
        return self;
    }

    pub fn addRoundKey(self: State, key: [16]u8) void {
        for (self.mat, key, 0..) |state, k, i| {
            self.mat[i] = state ^ k;
        }
    }
};
