const std = @import("std");
const mem = std.mem;

const Arguments = struct {
    output_path: []const u8,
    have_kernel_rwf_t: bool,
    have_kernel_timespec: bool,
    have_open_how: bool,
    have_futexv: bool,
    have_idtype_t: bool,

    fn from_process_args() !Arguments {
        var output_path: ?[]const u8 = null;
        var have_kernel_rwf_t = false;
        var have_kernel_timespec = false;
        var have_open_how = false;
        var have_futexv = false;
        var have_idtype_t = false;

        var it = std.process.args();
        _ = it.skip();

        while (true) {
            const arg = it.next() orelse break;

            if (mem.eql(u8, "-o", arg)) {
                output_path = it.next() orelse return error.MissingParam;
            } else if (mem.eql(u8, "--have-kernel-rwf-t", arg)) {
                have_kernel_rwf_t = true;
            } else if (mem.eql(u8, "--have-kernel-timespec", arg)) {
                have_kernel_timespec = true;
            } else if (mem.eql(u8, "--have-open-how", arg)) {
                have_open_how = true;
            } else if (mem.eql(u8, "--have-futexv", arg)) {
                have_futexv = true;
            } else if (mem.eql(u8, "--have-idtype-t", arg)) {
                have_idtype_t = true;
            }
        }

        return Arguments{
            .output_path = output_path orelse return error.NoOutputPath,
            .have_kernel_rwf_t = have_kernel_rwf_t,
            .have_kernel_timespec = have_kernel_timespec,
            .have_open_how = have_open_how,
            .have_futexv = have_futexv,
            .have_idtype_t = have_idtype_t,
        };
    }
};

pub fn main() !void {
    const args = try Arguments.from_process_args();

    const file = try std.fs.cwd().createFile(args.output_path, .{});
    defer file.close();

    const writer = file.writer();

    try writer.writeAll(
        \\/* SPDX-License-Identifier: MIT */
        \\#ifndef LIBURING_COMPAT_H
        \\#define LIBURING_COMPAT_H
        \\
        \\
    );

    if (!args.have_kernel_rwf_t)
        try writer.writeAll("typedef int __kernel_rwf_t;\n\n");

    if (!args.have_kernel_timespec)
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

    if (!args.have_open_how)
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

    if (!args.have_futexv)
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

    if (!args.have_idtype_t)
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
}
