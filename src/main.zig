const std = @import("std");
const Io = std.Io;
const mem = std.mem;

const zebra = @import("zebra");

fn usage() void {
    std.debug.print(
        \\Usage: zebra [options] [file]...
        \\Concatenate files to standard output.
        \\
        \\Options:
        \\  --help
        \\
    , .{});
}

fn cat(io: Io, reader: *Io.File.Reader) !void {
    while (reader.interface.takeDelimiterInclusive('\n')) |line| {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
        const stdout_writer = &stdout_file_writer.interface;
        _ = try stdout_writer.write(line);
        try stdout_writer.flush();
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => |e| return e,
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);

    if (args.len < 2) {
        var stdin_buffer: [1024]u8 = undefined;
        var stdin_reader = Io.File.stdin().reader(io, &stdin_buffer);
        try cat(io, &stdin_reader);
        return;
    }

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (mem.eql(u8, args[i], "--help")) {
            usage();
            return;
        } else if (mem.startsWith(u8, args[i], "-")) {
            usage();
            std.process.exit(1);
        }
    }

    i = 1;
    while (i < args.len) : (i += 1) {
        var buffer: [1024]u8 = undefined;
        var file = try Io.Dir.cwd().openFile(io, args[i], .{});
        var reader = file.reader(io, &buffer);
        try cat(io, &reader);
    }
}
