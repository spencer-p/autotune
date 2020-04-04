const std = @import("std");
const warn = std.debug.warn;
usingnamespace @cImport(@cInclude("alsa/asoundlib.h"));

const device = "default";

var output: ?snd_output_t = null;
var buf: [16 * 1024]u8 = undefined;

fn checkAlsa(err: c_int) !void {
    if (err < 0) {
        warn("ALSA error: {s} ({d})\n", .{ snd_strerror(err), -err });
        return error.AlsaError; // TODO switch on error type
    }
}

pub fn main() !void {

    // Open a handle for writing
    var handle: ?*snd_pcm_t = null;
    checkAlsa(snd_pcm_open(&handle, device, .SND_PCM_STREAM_PLAYBACK, 0)) catch {
        warn("failed to open alsa handle\n", .{});
        return;
    };
    defer _ = snd_pcm_close(handle);

    // Set parameters of the handle
    checkAlsa(snd_pcm_set_params(
        handle,
        .SND_PCM_FORMAT_U8,
        .SND_PCM_ACCESS_RW_INTERLEAVED,
        1,
        48000,
        1,
        500000,
    )) catch {
        warn("failed to set handle parameters\n", .{});
        return;
    };

    var i: usize = 0;
    while (i < 16) : (i += 1) {
        // Perform a write
        var frames = @intCast(i32, snd_pcm_writei(handle, &buf, buf.len));

        // Attempt to recover a potential error once
        checkAlsa(frames) catch {
            warn("attempting recovery of handle\n", .{});
            frames = snd_pcm_recover(handle, frames, 0);
        };
        checkAlsa(frames) catch {
            warn("irrecoverable write error\n", .{});
            return;
        };

        // Check for short write
        if (frames > 0 and frames < buf.len) {
            warn("short write of {} bytes, expected {}\n", .{
                frames,
                buf.len,
            });
        }
    }
}
