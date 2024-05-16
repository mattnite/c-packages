const std = @import("std");
const Build = std.Build;

const version = .{
    .major = 2,
    .minor = 5,
};

pub const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .powerpc64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .powerpc64, .os_tag = .linux, .abi = .musl },
};

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const link_libc = b.option(bool, "link_libc", "Whether to link libc") orelse true;
    const have_kernel_rwf_t = b.option(bool, "have_kernel_rwf_t", "") orelse true;
    const have_kernel_timespec = b.option(bool, "have_kernel_timespec", "") orelse true;
    const have_open_how = b.option(bool, "have_open_how", "") orelse true;
    const have_futexv = b.option(bool, "have_futexv", "") orelse true;
    const have_idtype_t = b.option(bool, "have_idtype_t", "") orelse true;

    const writefiles = b.addWriteFiles();
    const compat_h = write_compat_h(b, writefiles, .{
        .have_kernel_rwf_t = have_kernel_rwf_t,
        .have_kernel_timespec = have_kernel_timespec,
        .have_open_how = have_open_how,
        .have_futexv = have_futexv,
        .have_idtype_t = have_idtype_t,
    }) catch @panic("OOM");

    const version_h = write_version_h(b, writefiles, .{
        .major = version.major,
        .minor = version.minor,
    }) catch @panic("OOM");

    const uring = b.addStaticLibrary(.{
        .name = "uring",
        .target = target,
        .optimize = optimize,
        .link_libc = link_libc,
    });
    uring.defineCMacro("_GNU_SOURCE", null);
    uring.addCSourceFiles(.{ .files = srcs, .flags = &.{} });
    if (!link_libc)
        uring.addCSourceFile(.{
            .file = .{ .path = "c/src/nolibc.c" },
            .flags = &.{},
        });

    uring.addIncludePath(b.path("c/src/include"));
    uring.addIncludePath(compat_h.dirname().dirname());
    uring.addIncludePath(version_h.dirname().dirname());

    uring.installHeader(b.path("c/src/include/liburing.h"), "liburing.h");
    uring.installHeader(b.path("c/src/include/liburing/io_uring.h"), "liburing/io_uring.h");
    uring.installHeader(b.path("c/src/include/liburing/barrier.h"), "liburing/barrier.h");
    uring.installHeader(compat_h, "liburing/compat.h");
    uring.installHeader(version_h, "liburing/io_uring_version.h");

    b.installArtifact(uring);

    // a test step is needed for c-packages, but it ultimately does nothing for this project
    _ = b.step("test", "Run tests");
}

const VersionHeaderOptions = struct {
    major: u32,
    minor: u32,
};

fn write_version_h(b: *Build, writefile: *Build.Step.WriteFile, opts: VersionHeaderOptions) !Build.LazyPath {
    var text = std.ArrayList(u8).init(b.allocator);
    defer text.deinit();

    try text.writer().print(
        \\/* SPDX-License-Identifier: MIT */
        \\#ifndef LIBURING_VERSION_H
        \\#define LIBURING_VERSION_H
        \\
        \\#define IO_URING_VERSION_MAJOR {}
        \\#define IO_URING_VERSION_MINOR {}
        \\
        \\#endif
        \\
    ,
        .{ opts.major, opts.minor },
    );

    return writefile.add("liburing/io_uring_version.h", try text.toOwnedSlice());
}

const CompatHeaderOptions = struct {
    have_kernel_rwf_t: bool,
    have_kernel_timespec: bool,
    have_open_how: bool,
    have_futexv: bool,
    have_idtype_t: bool,
};

fn write_compat_h(b: *Build, writefile: *Build.Step.WriteFile, opts: CompatHeaderOptions) !Build.LazyPath {
    var text = std.ArrayList(u8).init(b.allocator);
    defer text.deinit();

    const writer = text.writer();
    try writer.writeAll(
        \\/* SPDX-License-Identifier: MIT */
        \\#ifndef LIBURING_COMPAT_H
        \\#define LIBURING_COMPAT_H
        \\
        \\
    );

    if (!opts.have_kernel_rwf_t)
        try writer.writeAll("typedef int __kernel_rwf_t;\n\n");

    if (!opts.have_kernel_timespec)
        try writer.writeAll(
            \\#include <stdint.h>
            \\
            \\struct __kernel_timespec {
            \\	int64_t		tv_sec;
            \\	long long	tv_nsec;
            \\};
            \\
            \\/* <linux/time_types.h> is not available, so it can't be included */
            \\#define UAPI_LINUX_IO_URING_H_SKIP_LINUX_TIME_TYPES_H 1
            \\
            \\
        )
    else
        try writer.writeAll(
            \\#include <linux/time_types.h>
            \\/* <linux/time_types.h> is included above and not needed again */
            \\#define UAPI_LINUX_IO_URING_H_SKIP_LINUX_TIME_TYPES_H 1
            \\
        );

    if (!opts.have_open_how)
        try writer.writeAll(
            \\#include <inttypes.h>
            \\
            \\struct open_how {
            \\	uint64_t	flags;
            \\	uint64_t	mode;
            \\	uint64_t	resolve;
            \\};
            \\
            \\
        )
    else
        try writer.writeAll("#include <linux/openat2.h>\n\n");

    try writer.writeAll("#include <sys/stat.h>\n\n");

    if (!opts.have_futexv)
        try writer.writeAll(
            \\#include <inttypes.h>
            \\
            \\#define FUTEX_32	2
            \\#define FUTEX_WAITV_MAX	128
            \\
            \\struct futex_waitv {
            \\	uint64_t	val;
            \\	uint64_t	uaddr;
            \\	uint32_t	flags;
            \\	uint32_t	__reserved;
            \\};
            \\
            \\
        );

    if (!opts.have_idtype_t)
        try writer.writeAll(
            \\typedef enum
            \\{
            \\  P_ALL,		/* Wait for any child.  */
            \\  P_PID,		/* Wait for specified process.  */
            \\  P_PGID		/* Wait for members of process group.  */
            \\} idtype_t;
            \\
            \\
        );

    try writer.writeAll("#endif\n");

    return writefile.add("liburing/compat.h", try text.toOwnedSlice());
}

const srcs = &.{
    "c/src/register.c",
    "c/src/queue.c",
    "c/src/syscall.c",
    "c/src/setup.c",
    "c/src/version.c",
};
