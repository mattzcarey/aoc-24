const std = @import("std");

fn isAllDigits(slice: []const u8) bool {
    for (slice) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }
    return true;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/3/input.txt", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const contents = try file.readToEndAlloc(std.heap.page_allocator, file_size);
    defer std.heap.page_allocator.free(contents);

    var total: i64 = 0;
    var index: usize = 0;
    var mul_enabled: bool = true;

    const patterns = [_][]const u8{ "mul(", "do(", "don't(" };

    while (index < contents.len) {
        var min_pos: ?usize = null;
        var min_pattern_index: usize = 0;

        for (patterns, 0..) |pattern, i| {
            const pos = std.mem.indexOf(u8, contents[index..], pattern);
            if (pos) |p| {
                const abs_pos = index + p;
                if (min_pos == null or abs_pos < min_pos.?) {
                    min_pos = abs_pos;
                    min_pattern_index = i;
                }
            }
        }

        if (min_pos == null) break;

        index = min_pos.?;

        if (std.mem.startsWith(u8, contents[index..], "do(")) {
            mul_enabled = true;
            index += 3; // Move past "do("
            const end = std.mem.indexOf(u8, contents[index..], ")");
            if (end != null) {
                index += end.? + 1; // Move past ")"
            }
        } else if (std.mem.startsWith(u8, contents[index..], "don't(")) {
            mul_enabled = false;
            index += 6; // Move past "don't("
            const end = std.mem.indexOf(u8, contents[index..], ")");
            if (end != null) {
                index += end.? + 1; // Move past ")"
            }
        } else if (std.mem.startsWith(u8, contents[index..], "mul(")) {
            index += 4; // Move past "mul("

            const comma = std.mem.indexOf(u8, contents[index..], ",");
            if (comma == null) {
                index += 1;
                continue;
            }

            if (!isAllDigits(contents[index .. index + comma.?])) {
                index += 1;
                continue;
            }

            const end = std.mem.indexOf(u8, contents[index + comma.? + 1 ..], ")");
            if (end == null) {
                index += 1;
                continue;
            }

            if (!isAllDigits(contents[index + comma.? + 1 .. index + comma.? + 1 + end.?])) {
                index += 1;
                continue;
            }

            if (mul_enabled) {
                const num1 = try std.fmt.parseInt(i64, contents[index .. index + comma.?], 10);
                const num2 = try std.fmt.parseInt(i64, contents[index + comma.? + 1 .. index + comma.? + 1 + end.?], 10);
                total += num1 * num2;
            }

            index += comma.? + 1 + end.? + 1; // Move past ")"
        } else {
            index += 1;
        }
    }

    std.debug.print("Total: {}\n", .{total});
}
