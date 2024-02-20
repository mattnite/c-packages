const std = @import("std");

const Build = std.Build;

const projects = .{
    .{ "liburing", @import("liburing") },
    .{ "ebur128", @import("ebur128") },
};

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});
    inline for (projects) |entry| {
        for (entry[1].targets) |target| {
            const dep = b.dependency(entry[0], .{
                .target = target,
                .optimize = optimize,
            });

            b.getInstallStep().dependOn(dep.builder.getInstallStep());
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
