const std = @import("std");
const Io = std.Io;
const process = std.process;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    // walk through test use cases
    // run cat against the input provided
    // put stdout into "expected-output"

    const use_cases_dir = try Io.Dir.cwd().openDir(io, "test/use-cases", .{ .iterate = true });
    var iter = use_cases_dir.iterateAssumeFirstIteration();

    while (try iter.next(io)) |entry| {
        const use_case_name = entry.name;
        const use_case_dir = try iter.reader.dir.openDir(io, use_case_name, .{});

        var cat_stdin_file: ?Io.File = null;
        if (use_case_dir.openFile(io, "stdin", .{})) |file| {
            cat_stdin_file = file;
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => {
                std.debug.print("failed to read stdin file", .{});
            },
        }

        var cat_argv_list: std.ArrayList([]const u8) = .empty;
        defer cat_argv_list.deinit(arena);
        try cat_argv_list.append(arena, "cat");

        if (use_case_dir.openFile(io, "argv", .{})) |file| {
            defer file.close(io);
            var argv_buffer: [1024]u8 = undefined;
            var argv_reader = file.reader(io, &argv_buffer);
            while (try argv_reader.interface.takeDelimiter('\n')) |arg| {
                try cat_argv_list.append(arena, arg);
            }
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => |e| {
                std.debug.print("failed to read argv file: {s}", .{@errorName(e)});
                std.process.exit(1);
            },
        }

        const cat_argv = cat_argv_list.items;
        const cat_output_file = try use_case_dir.createFile(io, "expected-output", .{ .truncate = true });
        var cat_spawn_options: process.SpawnOptions = .{ .argv = cat_argv, .cwd = .{ .dir = use_case_dir }, .stdin = .ignore, .stdout = .{ .file = cat_output_file }, .stderr = .ignore };
        if (cat_stdin_file) |file| {
            cat_spawn_options.stdin = .{ .file = file };
        }

        var child = try process.spawn(io, cat_spawn_options);
        defer child.kill(io);

        const term = try child.wait(io);
        switch (term) {
            .exited => {
                std.debug.print("output for {s} generated successfully\n", .{use_case_name});
            },
            else => |t| {
                std.debug.print("cat failed with {c}", .{@as(u8, @truncate(@intFromEnum(t)))});
                std.process.exit(1);
            },
        }
    }
}
