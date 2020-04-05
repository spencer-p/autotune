const std = @import("std");
const math = std.math;

var prng = std.rand.DefaultPrng.init(0);

fn sinWave(amp: f64, wlength: f64, i: usize) f64 {
    return amp * math.sin(@intToFloat(f64, i) * math.tau / wlength);
}

fn makeSinBuf(comptime shift: f64, comptime amp: f64, comptime wlength: f64, comptime numwaves: usize) []u8 {
    // algoithm runs in something like numwaves * wlength, give it extra
    // padding just to be sure. defer resetting the branch quota.
    @setEvalBranchQuota(1000 * numwaves * @floatToInt(usize, wlength));
    defer @setEvalBranchQuota(1000);

    var buf: [@floatToInt(usize, wlength)]u8 = undefined;
    var i: usize = 0;
    while (i < buf.len) : (i += 1) {
        buf[i] = @floatToInt(u8, shift);
    }

    var wavei: usize = 1;
    while (wavei <= numwaves) : (wavei += 1) {
        i = 0;
        while (i < buf.len) : (i += 1) {
            var sample = sinWave(amp, wlength / @intToFloat(f64, wavei), i);
            if (sample < 0) {
                buf[i] -= @floatToInt(u8, -sample);
            } else {
                buf[i] += @floatToInt(u8, sample);
            }
        }
    }

    return buf[0..];
}

const number_of_harmonics = 8;
const sin_table = makeSinBuf(128, 16, 128, number_of_harmonics);

pub fn fillBuf(f: fn (usize) u8, buf: []u8) void {
    var i: usize = 0;
    while (i < buf.len) : (i += 1) {
        buf[i] = f(i);
    }
}

pub fn randBytes(_: usize) u8 {
    return prng.random.int(u8);
}

pub fn sineBytes(i: usize) u8 {
    return sin_table[i % sin_table.len];
}
