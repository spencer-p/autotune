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

    // Each index of the buffer will be the shift + the sum of all waves at
    // that index.

    // Start with the shift
    var buf = [_]u8{@floatToInt(u8, shift)} ** @floatToInt(usize, wlength);

    // Calculate for each wave:
    var wavei: usize = 1;
    while (wavei <= numwaves) : (wavei += 1) {

        // At each index, add that part of the wave:
        var i: usize = 0;
        while (i < buf.len) : (i += 1) {
            var sample = sinWave(amp, wlength / @intToFloat(f64, wavei), i);

            // Calculate the absolute value of the wav and apply it in the
            // correct direction, additive or subtractive
            if (sample < 0) {
                buf[i] -= @floatToInt(u8, -sample);
            } else {
                buf[i] += @floatToInt(u8, sample);
            }
        }
    }

    return buf[0..];
}

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
    const number_of_harmonics = 8;
    const sin_table = makeSinBuf(128, 16, 128, number_of_harmonics);

    return sin_table[i % sin_table.len];
}
