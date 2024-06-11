const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("bindings", .{
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.linkSystemLibrary("capstone");

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const run_unit_tests_target = b.step("unit-test", "Run all the unit tests");
    run_unit_tests_target.dependOn(&run_unit_tests.step);

    const run_tests = b.step("test", "Run all the tests");
    run_tests.dependOn(run_unit_tests_target);

    // add examples like https://github.com/MoAlyousef/zfltk/blob/main/build.zig
}
