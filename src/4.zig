const std = @import("std");

const Pattern = struct {
    row: usize,
    col: usize,
};

fn checkXMAS(grid: []const []const u8, start_row: usize, start_col: usize) bool {
    // Check if we have enough space around the position
    if (start_row < 1 or start_row >= grid.len - 1 or
        start_col < 1 or start_col >= grid[0].len - 1)
    {
        return false;
    }

    // Check center 'A'
    if (grid[start_row][start_col] != 'A') return false;

    // Check all possible combinations of MAS in X shape
    const patterns = [4][2][]const u8{
        [_][]const u8{ "MAS", "MAS" },
        [_][]const u8{ "MAS", "SAM" },
        [_][]const u8{ "SAM", "MAS" },
        [_][]const u8{ "SAM", "SAM" },
    };

    for (patterns) |pattern| {
        const forward = pattern[0];
        const backward = pattern[1];

        // Check top-left to bottom-right
        if (grid[start_row - 1][start_col - 1] == forward[0] and
            grid[start_row + 1][start_col + 1] == forward[2])
        {
            // Check top-right to bottom-left
            if (grid[start_row - 1][start_col + 1] == backward[0] and
                grid[start_row + 1][start_col - 1] == backward[2])
            {
                return true;
            }
        }
    }

    return false;
}

pub fn findXMAS(allocator: std.mem.Allocator, grid: []const []const u8) !std.ArrayList(Pattern) {
    var patterns = std.ArrayList(Pattern).init(allocator);

    // Start from 1 and end at len-1 since we need space for the X pattern
    var i: usize = 1;
    while (i < grid.len - 1) : (i += 1) {
        var j: usize = 1;
        while (j < grid[i].len - 1) : (j += 1) {
            if (checkXMAS(grid, i, j)) {
                try patterns.append(.{ .row = i, .col = j });
            }
        }
    }

    return patterns;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data/4/input.txt", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(content);

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var line_iter = std.mem.splitAny(u8, content, "\n");
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(line);
    }

    var patterns = try findXMAS(allocator, lines.items);
    defer patterns.deinit();

    std.debug.print("Found {d} X-MAS patterns\n", .{patterns.items.len});
}
