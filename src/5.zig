const std = @import("std");

const Rule = struct { before: u32, after: u32 };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data/5/input.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(content);

    var lines = std.mem.tokenizeAny(u8, content, "\n");
    var rules = std.ArrayList(Rule).init(allocator);
    defer rules.deinit();

    var valid_sum: u32 = 0;
    var invalid_sum: u32 = 0;

    // Parse rules until we hit the sequence lines
    var first_sequence_line: ?[]const u8 = null;
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, ",") != null) {
            first_sequence_line = line;
            break;
        }
        var parts = std.mem.splitAny(u8, line, "|");
        try rules.append(.{
            .before = try std.fmt.parseInt(u32, parts.next() orelse return error.InvalidInput, 10),
            .after = try std.fmt.parseInt(u32, parts.next() orelse return error.InvalidInput, 10),
        });
    }

    try processSequences(&lines, allocator, rules.items, &valid_sum, &invalid_sum, first_sequence_line);
    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ valid_sum, invalid_sum });
}

fn processSequences(
    lines: *std.mem.TokenIterator(u8, .any),
    allocator: std.mem.Allocator,
    rules: []const Rule,
    valid_sum: *u32,
    invalid_sum: *u32,
    first_line: ?[]const u8,
) !void {
    var sequence = std.ArrayList(u32).init(allocator);
    defer sequence.deinit();

    // Process the first line if we have one
    if (first_line) |line| {
        try processLine(line, &sequence, rules, valid_sum, invalid_sum, allocator);
    }

    while (lines.next()) |line| {
        try processLine(line, &sequence, rules, valid_sum, invalid_sum, allocator);
    }
}

// Helper function to avoid code duplication
fn processLine(
    line: []const u8,
    sequence: *std.ArrayList(u32),
    rules: []const Rule,
    valid_sum: *u32,
    invalid_sum: *u32,
    allocator: std.mem.Allocator,
) !void {
    sequence.clearRetainingCapacity();

    var nums = std.mem.splitScalar(u8, line, ',');
    while (nums.next()) |num_str| {
        const num = try std.fmt.parseInt(u32, std.mem.trim(u8, num_str, " "), 10);
        try sequence.append(num);
    }

    const mid = sequence.items[sequence.items.len / 2];
    if (isValidSequence(sequence.items, rules)) {
        valid_sum.* += mid;
    } else {
        const sorted = try sequence.toOwnedSlice();
        defer allocator.free(sorted);

        try sortByRules(sorted, rules, allocator);
        invalid_sum.* += sorted[sorted.len / 2];
    }
}

fn isValidSequence(sequence: []const u32, rules: []const Rule) bool {
    for (rules) |rule| {
        var before_idx: ?usize = null;
        var after_idx: ?usize = null;
        for (sequence, 0..) |num, i| {
            if (num == rule.before) before_idx = i;
            if (num == rule.after) after_idx = i;
        }
        if (before_idx != null and after_idx != null and before_idx.? >= after_idx.?) return false;
    }
    return true;
}

fn sortByRules(sequence: []u32, rules: []const Rule, allocator: std.mem.Allocator) !void {
    const PageNode = struct {
        page: u32,
        incoming_edges: usize,
        outgoing_edges: std.ArrayList(*@This()),
    };

    var page_map = std.AutoHashMap(u32, *PageNode).init(allocator);
    defer page_map.deinit();

    // Initialize nodes for each page in the sequence
    var nodes = std.ArrayList(PageNode).init(allocator);
    defer nodes.deinit();

    for (sequence) |page_num| {
        const node = PageNode{
            .page = page_num,
            .incoming_edges = 0,
            .outgoing_edges = std.ArrayList(*PageNode).init(allocator),
        };
        try nodes.append(node);
        try page_map.put(page_num, &nodes.items[nodes.items.len - 1]);
    }

    // Build graph edges based on the rules
    for (rules) |rule| {
        if (page_map.get(rule.before) != null and page_map.get(rule.after) != null) {
            const before_node = page_map.get(rule.before).?;
            const after_node = page_map.get(rule.after).?;
            try before_node.outgoing_edges.append(after_node);
            after_node.incoming_edges += 1;
        }
    }

    // Topological sort using Kahn's algorithm
    var sorted_pages = std.ArrayList(u32).init(allocator);
    defer sorted_pages.deinit();

    var no_incoming = std.ArrayList(*PageNode).init(allocator);
    defer no_incoming.deinit();

    for (nodes.items) |*node| {
        if (node.incoming_edges == 0) {
            try no_incoming.append(node);
        }
    }

    while (no_incoming.items.len > 0) {
        const node = no_incoming.orderedRemove(0);
        try sorted_pages.append(node.page);

        for (node.outgoing_edges.items) |neighbor| {
            neighbor.incoming_edges -= 1;
            if (neighbor.incoming_edges == 0) {
                try no_incoming.append(neighbor);
            }
        }
    }

    // Check for cycles
    if (sorted_pages.items.len != nodes.items.len) {
        return error.InvalidInput;
    }

    // Update the original sequence with the sorted sequence
    for (0..sequence.len) |i| {
        sequence[i] = sorted_pages.items[i];
    }
}
