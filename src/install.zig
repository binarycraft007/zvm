const std = @import("std");
const builtin = @import("builtin");
const hash = @import("hash.zig");
const download = @import("download.zig");
const architecture = @import("architecture.zig");
const Allocator = std.mem.Allocator;
const io = std.io;
const json = std.json;
const fs = std.fs;
const crypto = std.crypto;
const os = std.os;

const Version = struct {
    name: []const u8,
    date: ?[]const u8,
    tarball: ?[]const u8,
    shasum: ?[]const u8,
};

const Error = error{
    HttpError,
    UnsupportedVersion,
    JSONParsingFailed,
    MissingExpectedFields,
    FileError,
    HashMismatch,
};

fn fetchVersionData(allocator: Allocator, requested_version: []const u8, sub_key: []const u8) !?Version {
    const url = "https://ziglang.org/download/index.json";
    const uri = std.Uri.parse(url) catch unreachable;

    // Initialize HTTP client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Make the HTTP request
    var req = try client.request(.GET, uri, .{ .allocator = allocator }, .{});
    defer req.deinit();
    try req.start(.{});
    try req.wait();

    // Check if request was successful
    try std.testing.expect(req.response.status == .ok);

    // Read the response body with 256kb buffer allocation
    var buffer: [262144]u8 = undefined; // 256 * 1024 = 262kb
    const read_len = try req.readAll(buffer[0..]);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, buffer[0..read_len], .{});
    defer parsed.deinit();
    const root = parsed.value;

    var it = root.object.iterator();
    while (it.next()) |entry| {
        // const key_ptr = entry.key_ptr;
        // const key = key_ptr.*;
        if (std.mem.eql(u8, entry.key_ptr.*, requested_version)) {
            // Initialize fields with null.
            var date: ?[]const u8 = null;
            var tarball: ?[]const u8 = null;
            var shasum: ?[]const u8 = null;

            var valObj = entry.value_ptr.*.object.iterator();
            while (valObj.next()) |value| {
                if (std.mem.eql(u8, value.key_ptr.*, "date")) {
                    date = value.value_ptr.*.string;
                } else if (std.mem.eql(u8, value.key_ptr.*, sub_key)) {
                    const nestedObjConst = value.value_ptr.*.object.iterator();
                    var nestedObj = nestedObjConst;
                    while (nestedObj.next()) |nestedValue| {
                        if (std.mem.eql(u8, nestedValue.key_ptr.*, "tarball")) {
                            tarball = nestedValue.value_ptr.*.string;
                        } else if (std.mem.eql(u8, nestedValue.key_ptr.*, "shasum")) {
                            shasum = nestedValue.value_ptr.*.string;
                        }
                    }
                }
            }

            // Validate that we found all the required fields.
            if (date == null or tarball == null or shasum == null) {
                return Error.MissingExpectedFields;
            }

            // Create the Version struct.
            return Version{
                .name = try allocator.dupe(u8, requested_version),
                .date = try allocator.dupe(u8, date.?),
                .tarball = try allocator.dupe(u8, tarball.?),
                .shasum = try allocator.dupe(u8, shasum.?),
            };
        }
    }

    return null;
}

pub fn fromVersion(version: []const u8) !void {
    var allocator = std.heap.page_allocator;
    const platform = try architecture.detect(allocator, architecture.DetectParams{ .os = builtin.os.tag, .arch = builtin.cpu.arch, .reverse = true }) orelse unreachable;
    defer allocator.free(platform);
    const version_data = try fetchVersionData(allocator, version, platform);
    if (version_data) |data| {
        std.debug.print("Install {s}\n", .{data.name});

        // Download and verify
        _ = try download.content(allocator, data.name, data.tarball.?);
        //const computedHash: [32]u8 = hash.computeSHA256(content);
        //std.debug.print("Computed hash {s}\n", .{computedHash});
        //if (!hash.verifyHash(computedHash, data.shasum.?)) {
        //  return error.HashMismatch;
        //}

    } else {
        return Error.UnsupportedVersion;
    }
}
