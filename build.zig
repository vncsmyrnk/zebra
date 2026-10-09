const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zebra",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{},
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const cat_test_exe = b.addExecutable(.{
        .name = "zebra-test-cat-output-generator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/cat_output_generator.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{},
        }),
    });
    const cat_test_run = b.addRunArtifact(cat_test_exe);
    const cat_test_step = b.step("cat-output-generator", "Generate standard output reference using cat for tests");
    cat_test_step.dependOn(&cat_test_run.step);

    const unit_tests = b.addExecutable(.{
        .name = "zebra-test-runner",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/runner.zig"),
            .target = target,
        }),
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_unit_tests.step);
    run_unit_tests.addArtifactArg(exe);
}
