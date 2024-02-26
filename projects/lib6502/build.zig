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

    const lib6502 = b.addStaticLibrary(.{
        .name = "6502",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib6502.addCSourceFile(.{
        .file = .{ .path = "c/lib6502.c" },
        .flags = &.{},
    });
    lib6502.installHeader("c/lib6502.h", "lib6502.h");
    b.installArtifact(lib6502);

    const module = b.addModule("6502", .{
        .root_source_file = .{ .path = "zig/bindings.zig" },
    });
    module.linkLibrary(lib6502);

    const run6502 = b.addExecutable(.{
        .name = "run6502",
        .target = target,
        .optimize = optimize,
    });
    run6502.addCSourceFile(.{
        .file = .{ .path = "c/run6502.c" },
        .flags = &.{},
    });
    run6502.linkLibrary(lib6502);
    b.installArtifact(run6502);

    _ = b.step("test", "Run tests");
}
