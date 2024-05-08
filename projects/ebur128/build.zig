const std = @import("std");
const Build = std.Build;

pub const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },

    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows },

    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
};

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ebur128 = b.addStaticLibrary(.{
        .name = "ebur128",
        .target = target,
        .optimize = optimize,
    });
    ebur128.addCSourceFile(.{
        .file = .{ .path = "c/ebur128/ebur128.c" },
        .flags = &.{},
    });
    ebur128.addIncludePath(.{ .path = "c/ebur128/queue" });
    ebur128.installHeader(.{ .path = "c/ebur128/ebur128.h" }, "ebur128.h");
    ebur128.linkSystemLibrary("m");
    b.installArtifact(ebur128);

    const ebur128_module = b.addModule("ebur128", .{
        .root_source_file = .{ .path = "zig/bindings.zig" },
    });
    ebur128_module.linkLibrary(ebur128);

    // c-packges requires a test step, it does nothing for this project right
    // now
    _ = b.step("test", "Run tests");
}
