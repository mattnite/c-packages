const std = @import("std");
const Build = std.Build;

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

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const z = b.addStaticLibrary(.{
        .name = "z",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    z.addCSourceFiles(.{
        .files = &.{
            "c/adler32.c",
            "c/compress.c",
            "c/crc32.c",
            "c/deflate.c",
            "c/gzclose.c",
            "c/gzlib.c",
            "c/gzread.c",
            "c/gzwrite.c",
            "c/inflate.c",
            "c/infback.c",
            "c/inftrees.c",
            "c/inffast.c",
            "c/trees.c",
            "c/uncompr.c",
            "c/zutil.c",
        },
        .flags = &.{"-std=c89"},
    });
    z.installHeader(.{ .path = "c/zlib.h" }, "zlib.h");
    z.installHeader(.{ .path = "c/zconf.h" }, "zconf.h");
    b.installArtifact(z);

    const mod = b.addModule("z", .{
        .root_source_file = .{ .path = "zig/bindings.zig" },
    });
    mod.linkLibrary(z);

    const example_exe = b.addExecutable(.{
        .name = "example",
        .link_libc = true,
        .target = b.host,
    });
    example_exe.linkLibrary(z);
    example_exe.addCSourceFile(.{
        .file = .{ .path = "c/test/example.c" },
        .flags = &.{},
    });

    const example_run = b.addRunArtifact(example_exe);

    const example64_exe = b.addExecutable(.{
        .name = "example64",
        .link_libc = true,
        .target = b.host,
    });
    example64_exe.linkLibrary(z);
    example64_exe.addCSourceFile(.{
        .file = .{ .path = "c/test/example.c" },
        .flags = &.{"-D_FILE_OFFSET_BITS=64"},
    });

    const example64_run = b.addRunArtifact(example64_exe);

    const module_test = b.addTest(.{
        .root_source_file = .{ .path = "zig/bindings.zig" },
    });
    module_test.linkLibrary(z);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&example_run.step);
    test_step.dependOn(&example64_run.step);
    test_step.dependOn(&module_test.step);
}
