const std = @import("std");
const math = std.math;

var prng = std.rand.DefaultPrng.init(0);

const sin_table = {
    // Build a compile time sine wave with
    // f(x) = shift + amp*sin(x * tau/freq)
    const shift = 128;
    const amp = 127;
    const freq = 64;
    var buf: [freq]u8 = undefined;
    var i: usize = 0;
    while (i < buf.len) : (i += 1) {
        buf[i] = @floatToInt(u8, shift + amp *
            math.sin(@intToFloat(f64, i) * math.tau / freq));
    }
    return buf;
};

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
