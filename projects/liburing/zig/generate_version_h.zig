const std = @import("std");
const mem = std.mem;

const Arguments = struct {
    output_path: []const u8,
    version_major: u32,
    version_minor: u32,

    fn from_process_args() !Arguments {
        var output_path: ?[]const u8 = null;
        var version_major: ?u32 = null;
        var version_minor: ?u32 = null;

        var it = std.process.args();
        _ = it.skip();

        while (true) {
            const arg = it.next() orelse break;

            if (mem.eql(u8, "-o", arg)) {
                output_path = it.next() orelse return error.MissingParam;
            } else if (mem.eql(u8, "--version-major", arg)) {
                const str = it.next() orelse return error.MissingParam;
                version_major = try std.fmt.parseInt(u32, str, 10);
            } else if (mem.eql(u8, "--version-minor", arg)) {
                const str = it.next() orelse return error.MissingParam;
                version_minor = try std.fmt.parseInt(u32, str, 10);
            }
        }

        return Arguments{
            .output_path = output_path orelse return error.NoOutputPath,
            .version_major = version_major orelse return error.NoVersionMajor,
            .version_minor = version_minor orelse return error.NoVersionMinor,
        };
    }
};

pub fn main() !void {
    const args = try Arguments.from_process_args();

    const file = try std.fs.cwd().createFile(args.output_path, .{});
    defer file.close();

    try file.writer().print(
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
        .{ args.version_major, args.version_minor },
    );
}
