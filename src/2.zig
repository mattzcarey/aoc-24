const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/2/input.txt", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const contents = try file.readToEndAlloc(std.heap.page_allocator, file_size);
    defer std.heap.page_allocator.free(contents);

    var lines = std.mem.splitScalar(u8, contents, '\n');

    var safe_count: u32 = 0;

    while (lines.next()) |line| {
        var parts = std.mem.tokenizeAny(u8, line, " ");
        var levels = std.ArrayList(u32).init(std.heap.page_allocator);
        defer levels.deinit();

        while (parts.next()) |part| {
            const level = try std.fmt.parseInt(u32, part, 10);
            try levels.append(level);
        }

        if (isSafeReport(levels.items)) {
            safe_count += 1;
        }
    }

    std.debug.print("Number of safe reports: {}\n", .{safe_count});
}

fn isSafeReport(levels: []const u32) bool {
    if (levels.len < 2) return false;

    // Check if it's safe without removing any levels
    if (isSequenceSafe(levels)) return true;

    // Try removing each level one at a time
    for (levels, 0..) |_, skip_i| {
        var temp_levels = std.ArrayList(u32).init(std.heap.page_allocator);
        defer temp_levels.deinit();

        for (levels, 0..) |level, i| {
            if (i != skip_i) {
                temp_levels.append(level) catch continue;
            }
        }

        if (isSequenceSafe(temp_levels.items)) return true;
    }

    return false;
}

fn isSequenceSafe(levels: []const u32) bool {
    if (levels.len < 2) return false;

    const is_increasing = levels[1] > levels[0];
    for (levels[0 .. levels.len - 1], 0..) |level, i| {
        const next_level = levels[i + 1];
        const diff = if (next_level > level) next_level - level else level - next_level;

        if (diff < 1 or diff > 3) return false;
        if ((next_level > level) != is_increasing) return false;
    }

    return true;
}
