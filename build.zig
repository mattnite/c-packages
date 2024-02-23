const std = @import("std");

const Build = std.Build;

const projects = .{
    .{ "liburing", @import("liburing") },
    .{ "ebur128", @import("ebur128") },
    .{ "libyaml", @import("libyaml") },
    .{ "libcyaml", @import("libcyaml") },
    .{ "zlib", @import("zlib") },
};

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // build each project for each advertised target
    inline for (projects) |entry| {
        for (entry[1].targets) |target| {
            const dep = b.dependency(entry[0], .{
                .target = target,
                .optimize = optimize,
            });

            b.getInstallStep().dependOn(dep.builder.getInstallStep());
        }
    }

    // setup tests
    const test_step = b.step("test", "Run available tests");
    inline for (.{
        .Debug,
        .ReleaseSafe,
        .ReleaseSmall,
        .ReleaseFast,
    }) |test_optimize| {
        inline for (projects) |entry| {
            const dep = b.dependency(entry[0], .{
                .optimize = test_optimize,
            });
            const project_test = dep.builder.top_level_steps.get("test") orelse {
                @panic(std.fmt.comptimePrint("project '{s}' does not have a test step in its build.zig", .{
                    entry[0],
                }));
            };
            test_step.dependOn(&project_test.step);
        }
    }

    const boxzer_dep = b.dependency("boxzer", .{});
    const boxzer_exe = boxzer_dep.artifact("boxzer");
    const boxzer_run = b.addRunArtifact(boxzer_exe);
    if (b.args) |args|
        boxzer_run.addArgs(args);

    const package_step = b.step("package", "Package monorepo using boxzer");
    package_step.dependOn(&boxzer_run.step);
}
