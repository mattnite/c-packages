const std = @import("std");

pub const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },

    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },

    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows },
};

const flags: []const []const u8 = &.{
    "-std=c11",
    "-Wall",
    "-Wextra",
    "-pedantic",
    "-Wconversion",
    "-Wwrite-strings",
    "-Wcast-align",
    "-Wpointer-arith",
    "-Winit-self",
    "-Wshadow",
    "-Wstrict-prototypes",
    "-Wmissing-prototypes",
    "-Wredundant-decls",
    "-Wundef",
    "-Wvla",
    "-Wdeclaration-after-statement",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libyaml_dep = b.dependency("libyaml", .{
        .target = target,
        .optimize = optimize,
    });

    const cyaml = b.addStaticLibrary(.{
        .name = "cyaml",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    cyaml.defineCMacro("VERSION_MAJOR", "1");
    cyaml.defineCMacro("VERSION_MINOR", "4");
    cyaml.defineCMacro("VERSION_PATCH", "1");
    cyaml.defineCMacro("VERSION_DEVEL", "0");
    cyaml.addIncludePath(.{ .path = "c/include" });
    cyaml.addCSourceFiles(.{
        .files = &.{
            "c/src/free.c",
            "c/src/load.c",
            "c/src/mem.c",
            "c/src/save.c",
            "c/src/utf8.c",
            "c/src/util.c",
        },
        .flags = flags,
    });
    cyaml.linkLibrary(libyaml_dep.artifact("yaml"));

    cyaml.installHeader(.{ .path = "c/include/cyaml/cyaml.h" }, "cyaml/cyaml.h");
    b.installArtifact(cyaml);

    const test_exe = b.addExecutable(.{
        .name = "test-cyaml",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    test_exe.addCSourceFiles(.{
        .files = &.{
            "c/test/units/free.c",
            "c/test/units/load.c",
            "c/test/units/test.c",
            "c/test/units/util.c",
            "c/test/units/errs.c",
            "c/test/units/file.c",
            "c/test/units/save.c",
            "c/test/units/utf8.c",
        },
        .flags = flags,
    });
    test_exe.linkLibrary(cyaml);
    std.fs.cwd().makePath("c/build") catch {};

    const test_run = b.addRunArtifact(test_exe);
    test_run.setCwd(.{ .path = "c" });
    // TODO: print stderr on failure

    const test_step = b.step("test", "Run test executable");
    test_step.dependOn(&test_run.step);
}
