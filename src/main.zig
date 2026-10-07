const std = @import("std");
const Io = std.Io;

const zebra = @import("zebra");

pub fn main(init: std.process.Init) !void {
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(init.io, &stdin_buffer);

    while (stdin_reader.interface.takeDelimiterInclusive('\n')) |line| {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_file_writer: Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
        const stdout_writer = &stdout_file_writer.interface;
        _ = try stdout_writer.write(line);
        try stdout_writer.flush();
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => |e| return e,
    }
}
