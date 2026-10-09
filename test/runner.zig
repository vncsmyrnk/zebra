const std = @import("std");
const Io = std.Io;
const debug = std.debug;
const process = std.process;
const testing = std.testing;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        debug.print("the runner requires the actual zebra binary path\n", .{});
        process.exit(1);
    }

    const use_cases_dir = try Io.Dir.cwd().openDir(io, "test/use-cases", .{ .iterate = true });
    var iter = use_cases_dir.iterateAssumeFirstIteration();

    while (try iter.next(io)) |entry| {
        const use_case_name = entry.name;
        const use_case_dir = try iter.reader.dir.openDir(io, use_case_name, .{});

        var zebra_stdin_file: ?Io.File = null;
        if (use_case_dir.openFile(io, "stdin", .{})) |file| {
            zebra_stdin_file = file;
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => {
                std.debug.print("failed to read stdin file", .{});
            },
        }

        var zebra_argv_list: std.ArrayList([]const u8) = .empty;
        defer zebra_argv_list.deinit(arena);
        try zebra_argv_list.append(arena, args[1]);

        if (use_case_dir.openFile(io, "argv", .{})) |file| {
            defer file.close(io);
            var argv_buffer: [1024]u8 = undefined;
            var argv_reader = file.reader(io, &argv_buffer);
            while (try argv_reader.interface.takeDelimiter('\n')) |arg| {
                try zebra_argv_list.append(arena, arg);
            }
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => |e| {
                std.debug.print("failed to read argv file: {s}", .{@errorName(e)});
                std.process.exit(1);
            },
        }

        const zebra_argv = zebra_argv_list.items;
        const zebra_output_file = try use_case_dir.createFile(io, "zebra-output", .{ .truncate = true });
        var zebra_spawn_options: process.SpawnOptions = .{ .argv = zebra_argv, .cwd = .inherit, .stdin = .ignore, .stdout = .{ .file = zebra_output_file }, .stderr = .ignore };
        if (zebra_stdin_file) |file| {
            zebra_spawn_options.stdin = .{ .file = file };
        }

        var child = try process.spawn(io, zebra_spawn_options);
        defer child.kill(io);

        const term = try child.wait(io);
        switch (term) {
            .exited => {},
            else => |t| {
                std.debug.print("zebra failed with {c}", .{@as(u8, @truncate(@intFromEnum(t)))});
                std.process.exit(1);
            },
        }

        const cat_output_file_contents = try use_case_dir.readFileAlloc(io, "expected-output", arena, .unlimited);
        const zebra_output_file_contents = try use_case_dir.readFileAlloc(io, "zebra-output", arena, .unlimited);
        try testing.expectEqualStrings(cat_output_file_contents, zebra_output_file_contents);
    }
}
