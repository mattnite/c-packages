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

    const config = b.addConfigHeader(
        .{ .style = .{ .cmake = b.path("c/src/config.h.in") } },
        .{
            .HAVE_STDBOOL_H = true,
        },
    );
    const version = b.addConfigHeader(.{
        .style = .{
            .cmake = b.path("c/src/cmark-gfm_version.h.in"),
        },
    }, .{
        .PROJECT_VERSION_MAJOR = "0",
        .PROJECT_VERSION_MINOR = "29",
        .PROJECT_VERSION_PATCH = "0",
        .PROJECT_VERSION_GFM = "13",
    });

    const cmark_lib = b.addStaticLibrary(.{
        .name = "cmark-gfm",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    cmark_lib.addConfigHeader(config);
    cmark_lib.addConfigHeader(version);
    cmark_lib.installConfigHeader(version);
    cmark_lib.addIncludePath(b.path("vendor"));
    cmark_lib.installHeader(b.path("c/src/cmark-gfm.h"), "cmark-gfm.h");
    cmark_lib.installHeader(b.path("vendor/cmark-gfm_export.h"), "cmark-gfm_export.h");
    cmark_lib.installHeader(b.path("c/src/cmark-gfm-extension_api.h"), "cmark-gfm-extension_api.h");
    cmark_lib.addCSourceFiles(.{
        .files = lib_src,
        .flags = &.{"-std=c99"},
    });
    b.installArtifact(cmark_lib);

    const cmark_extensions_lib = b.addStaticLibrary(.{
        .name = "cmark-gfm-extensions",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    cmark_extensions_lib.addConfigHeader(config);
    cmark_extensions_lib.addIncludePath(b.path("c/src"));
    cmark_extensions_lib.installHeader(
        b.path("c/extensions/cmark-gfm-core-extensions.h"),
        "cmark-gfm-core-extensions.h",
    );
    cmark_extensions_lib.installHeader(
        b.path("c/extensions/ext_scanners.h"),
        "ext_scanners.h",
    );
    cmark_extensions_lib.addCSourceFiles(.{
        .files = extensions_src,
        .flags = &.{"-std=c99"},
    });
    cmark_extensions_lib.linkLibrary(cmark_lib);

    b.installArtifact(cmark_extensions_lib);

    const cmark_exe = b.addExecutable(.{
        .name = "cmark-gfm-exe",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    cmark_exe.addConfigHeader(config);
    cmark_exe.addConfigHeader(version);
    cmark_exe.addCSourceFile(.{
        .file = b.path("c/src/main.c"),
        .flags = &.{"-std=c99"},
    });
    cmark_exe.linkLibrary(cmark_lib);
    cmark_exe.linkLibrary(cmark_extensions_lib);
    b.installArtifact(cmark_exe);

    _ = b.step("test", "Run tests");
}

const extensions_src: []const []const u8 = &.{
    "c/extensions/autolink.c",
    "c/extensions/core-extensions.c",
    "c/extensions/ext_scanners.c",
    "c/extensions/strikethrough.c",
    "c/extensions/table.c",
    "c/extensions/tagfilter.c",
    "c/extensions/tasklist.c",
};

const lib_src: []const []const u8 = &.{
    "c/src/xml.c",
    "c/src/cmark.c",
    "c/src/man.c",
    "c/src/buffer.c",
    "c/src/blocks.c",
    "c/src/cmark_ctype.c",
    "c/src/inlines.c",
    "c/src/latex.c",
    "c/src/houdini_href_e.c",
    "c/src/syntax_extension.c",
    "c/src/houdini_html_e.c",
    "c/src/plaintext.c",
    "c/src/utf8.c",
    "c/src/references.c",
    "c/src/render.c",
    "c/src/iterator.c",
    "c/src/arena.c",
    "c/src/linked_list.c",
    "c/src/commonmark.c",
    "c/src/map.c",
    "c/src/html.c",
    "c/src/plugin.c",
    "c/src/scanners.c",
    "c/src/footnotes.c",
    "c/src/houdini_html_u.c",
    "c/src/registry.c",
    "c/src/node.c",
};
