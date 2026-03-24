const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Interpreter = @import("interpreter.zig").Interpreter;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2) {
        std.log.err("Usage: lune <file.lune>", .{});
        return error.InvalidUsage;
    }

    const source = try std.fs.cwd().readFileAlloc(allocator, args[1], 1024 * 1024);

    var lexer = Lexer.init(allocator, source);
    const tokens = try lexer.tokenize();

    var parser = Parser.init(allocator, tokens);
    const program = try parser.parseProgram();

    var interpreter = Interpreter.init(allocator);
    defer interpreter.deinit();

    const result = try interpreter.runMain(program);
    std.debug.print("{d}\n", .{result});
}
