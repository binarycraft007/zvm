const std = @import("std");

pub fn list(allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
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

    // Initialize array list to hold versions
    var versions = std.ArrayList([]const u8).init(allocator);

    var it = root.object.iterator();
    while (it.next()) |entry| {
        const key_ptr = entry.key_ptr;
        const key = key_ptr.*;

        const key_copy = try allocator.dupe(u8, key);
        try versions.append(key_copy);
    }

    return versions;
}
