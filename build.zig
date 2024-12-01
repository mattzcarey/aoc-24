const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Create a run step for each day
    inline for (1..26) |day| {
        const day_name = b.fmt("{d}", .{day});
        const exe = b.addExecutable(.{
            .name = b.fmt("day{d}", .{day}),
            .root_source_file = b.path(b.fmt("src/{d}.zig", .{day})),
            .target = target,
            .optimize = optimize,
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        // Create a dedicated step for each day
        const run_step = b.step(day_name, b.fmt("Run day {d}", .{day}));
        run_step.dependOn(&run_cmd.step);
    }
}
