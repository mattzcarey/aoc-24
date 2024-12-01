const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/1/input.txt", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const contents = try file.readToEndAlloc(std.heap.page_allocator, file_size);
    defer std.heap.page_allocator.free(contents);

    var a = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer a.deinit();
    var b = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer b.deinit();

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeAny(u8, line, " ");

        if (parts.next()) |first| {
            try a.append(first);
        }
        if (parts.next()) |second| {
            try b.append(second);
        }
    }

    sort(a.items);
    sort(b.items);

    var sum: u32 = 0;
    for (a.items, b.items) |a_item, b_item| {
        const a_num = try std.fmt.parseInt(u32, a_item, 10);
        const b_num = try std.fmt.parseInt(u32, b_item, 10);
        sum += if (b_num > a_num) b_num - a_num else a_num - b_num;
    }

    std.debug.print("Sum (a): {}\n", .{sum});

    var freq = std.AutoHashMap(u32, u32).init(std.heap.page_allocator);
    defer freq.deinit();

    // Count frequencies in B
    for (b.items) |b_item| {
        const num = try std.fmt.parseInt(u32, b_item, 10);
        const entry = try freq.getOrPut(num);
        if (!entry.found_existing) {
            entry.value_ptr.* = 0;
        }
        entry.value_ptr.* += 1;
    }

    var sim: u32 = 0;
    for (a.items) |a_item| {
        const num = try std.fmt.parseInt(u32, a_item, 10);
        if (freq.get(num)) |count| {
            sim += num * count;
        }
    }

    std.debug.print("Similarity (b): {}\n", .{sim});
}

fn sort(list: [][]const u8) void {
    std.mem.sort([]const u8, list, {}, struct {
        fn lessThan(context: void, lhs: []const u8, rhs: []const u8) bool {
            _ = context; // autofix
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lessThan);
}
