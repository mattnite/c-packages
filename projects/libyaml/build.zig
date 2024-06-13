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

    const libyaml = b.addStaticLibrary(.{
        .name = "yaml",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    libyaml.defineCMacro("YAML_VERSION_MAJOR", "0");
    libyaml.defineCMacro("YAML_VERSION_MINOR", "2");
    libyaml.defineCMacro("YAML_VERSION_PATCH", "5");
    libyaml.defineCMacro("YAML_VERSION_STRING", "\"0.2.5\"");
    libyaml.defineCMacro("YAML_DECLARE_STATIC", "1");
    libyaml.addIncludePath(b.path("c/include"));
    libyaml.addCSourceFiles(.{
        .files = &.{
            "c/src/api.c",
            "c/src/dumper.c",
            "c/src/emitter.c",
            "c/src/loader.c",
            "c/src/parser.c",
            "c/src/reader.c",
            "c/src/scanner.c",
            "c/src/writer.c",
        },
        .flags = &.{},
    });
    libyaml.installHeader(b.path("c/include/yaml.h"), "yaml.h");
    b.installArtifact(libyaml);

    // c-packages requires a test step, but it does nothing for this project
    // right now.
    _ = b.step("test", "Run tests");
}
