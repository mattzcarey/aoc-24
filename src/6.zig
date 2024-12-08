const std = @import("std");

const Direction = enum {
    up,
    right,
    down,
    left,

    fn turnRight(self: Direction) Direction {
        return switch (self) {
            .up => .right,
            .right => .down,
            .down => .left,
            .left => .up,
        };
    }

    fn move(self: Direction, pos: Position) Position {
        return switch (self) {
            .up => Position{ .row = pos.row - 1, .col = pos.col },
            .right => Position{ .row = pos.row, .col = pos.col + 1 },
            .down => Position{ .row = pos.row + 1, .col = pos.col },
            .left => Position{ .row = pos.row, .col = pos.col - 1 },
        };
    }
};

fn starting_pos(grid: [][]const u8) Position {
    for (grid, 0..) |row, row_idx| {
        for (row, 0..) |cell, col_idx| {
            switch (cell) {
                '^', '>', 'v', '<' => return Position{
                    .row = @intCast(row_idx),
                    .col = @intCast(col_idx),
                },
                else => continue,
            }
        }
    }
    unreachable;
}

fn starting_dir(grid: [][]const u8) Direction {
    for (grid) |row| {
        for (row) |cell| {
            return switch (cell) {
                '^' => .up,
                '>' => .right,
                'v' => .down,
                '<' => .left,
                else => continue,
            };
        }
    }
    unreachable;
}

const Position = struct {
    row: i32,
    col: i32,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data/6/input.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(content);

    var grid = std.ArrayList([]u8).init(allocator);
    defer {
        for (grid.items) |row| {
            allocator.free(row);
        }
        grid.deinit();
    }

    try grid.ensureTotalCapacity(@divFloor(content.len, 2));

    var row_counter: usize = 0;
    var lines = std.mem.tokenizeAny(u8, content, "\n");
    while (lines.next()) |line| {
        const row_copy = try allocator.alloc(u8, line.len);
        @memcpy(row_copy, line);
        try grid.append(row_copy);

        row_counter += 1;
    }

    const start_pos = starting_pos(grid.items);
    const start_dir = starting_dir(grid.items);

    var possible_positions = std.AutoHashMap(Position, void).init(allocator);
    defer possible_positions.deinit();

    // Try placing an obstruction at each empty position
    for (grid.items, 0..) |row, row_idx| {
        for (row, 0..) |cell, col_idx| {
            if (cell != '.' or
                (row_idx == @as(usize, @intCast(start_pos.row)) and
                col_idx == @as(usize, @intCast(start_pos.col))))
            {
                continue;
            }

            // Place temporary obstruction
            grid.items[row_idx][col_idx] = '#';

            if (try willFormLoop(start_pos, start_dir, grid.items, allocator)) {
                try possible_positions.put(Position{
                    .row = @intCast(row_idx),
                    .col = @intCast(col_idx),
                }, {});
            }

            // Remove temporary obstruction
            grid.items[row_idx][col_idx] = '.';
        }
    }

    const result = possible_positions.count();
    try std.io.getStdOut().writer().print("\nPossible obstruction positions: {d}\n", .{result});
}

fn isInBounds(pos: Position, grid: [][]const u8) bool {
    return pos.row >= 0 and pos.row < grid.len and
        pos.col >= 0 and pos.col < grid[0].len;
}

fn willFormLoop(start_pos: Position, start_dir: Direction, grid: [][]const u8, allocator: std.mem.Allocator) !bool {
    var visited = std.AutoHashMap(struct { pos: Position, dir: Direction }, void).init(allocator);
    defer visited.deinit();

    var current_pos = start_pos;
    var current_dir = start_dir;
    var steps: usize = 0;
    const max_steps = grid.len * grid[0].len * 4;

    while (isInBounds(current_pos, grid)) {
        const state = .{ .pos = current_pos, .dir = current_dir };
        
        // If we've seen this state before, it's a loop
        if (visited.contains(state)) {
            // Make sure we've taken enough steps for it to be a meaningful loop
            return steps > 4;
        }
        
        try visited.put(state, {});
        steps += 1;

        // Prevent infinite loops by limiting total steps
        if (steps > max_steps) {
            return false;
        }

        const next_pos = current_dir.move(current_pos);

        if (!isInBounds(next_pos, grid)) {
            return false;
        } else if (grid[@intCast(next_pos.row)][@intCast(next_pos.col)] == '#') {
            current_dir = current_dir.turnRight();
        } else {
            current_pos = next_pos;
        }
    }
    return false;
}
