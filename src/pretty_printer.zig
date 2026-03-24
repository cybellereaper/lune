const std = @import("std");
const ast = @import("ast.zig");

pub fn render(allocator: std.mem.Allocator, program: ast.Program) ![]u8 {
    var out = std.ArrayList(u8).init(allocator);
    for (program.items, 0..) |item, i| {
        if (i > 0) try out.append('\n');
        switch (item) {
            .const_decl => |decl| {
                try out.writer().print("const {s} = ", .{decl.name});
                try printExpr(out.writer(), decl.value);
            },
            .function_decl => |decl| {
                try out.writer().print("fn {s}(", .{decl.name});
                for (decl.params, 0..) |param, idx| {
                    if (idx > 0) try out.writer().writeAll(", ");
                    try out.writer().writeAll(param);
                }
                try out.writer().writeAll(") {\n");
                try printBlock(out.writer(), decl.body, 1);
                try out.writer().writeAll("}");
            },
        }
    }
    return out.toOwnedSlice();
}

fn printBlock(writer: anytype, statements: []const ast.Stmt, indent: usize) !void {
    for (statements) |statement| {
        try printIndent(writer, indent);
        switch (statement) {
            .var_decl => |decl| {
                try writer.print("{s} := ", .{decl.name});
                try printExpr(writer, decl.value);
                try writer.writeByte('\n');
            },
            .assign => |assign| {
                try writer.print("{s} = ", .{assign.name});
                try printExpr(writer, assign.value);
                try writer.writeByte('\n');
            },
            .return_stmt => |expr| {
                try writer.writeAll("return");
                if (expr) |value| {
                    try writer.writeByte(' ');
                    try printExpr(writer, value);
                }
                try writer.writeByte('\n');
            },
            .if_stmt => |if_stmt| {
                try writer.writeAll("if ");
                try printExpr(writer, if_stmt.condition);
                try writer.writeAll(" {\n");
                try printBlock(writer, if_stmt.then_block, indent + 1);
                try printIndent(writer, indent);
                if (if_stmt.else_block.len == 0) {
                    try writer.writeAll("}\n");
                } else {
                    try writer.writeAll("} else {\n");
                    try printBlock(writer, if_stmt.else_block, indent + 1);
                    try printIndent(writer, indent);
                    try writer.writeAll("}\n");
                }
            },
            .while_stmt => |while_stmt| {
                try writer.writeAll("while ");
                try printExpr(writer, while_stmt.condition);
                try writer.writeAll(" {\n");
                try printBlock(writer, while_stmt.body, indent + 1);
                try printIndent(writer, indent);
                try writer.writeAll("}\n");
            },
            .expr_stmt => |expr| {
                try printExpr(writer, expr);
                try writer.writeByte('\n');
            },
        }
    }
}

fn printExpr(writer: anytype, expr: *const ast.Expr) !void {
    switch (expr.*) {
        .number => |n| try writer.print("{d}", .{n}),
        .boolean => |b| try writer.writeAll(if (b) "true" else "false"),
        .variable => |name| try writer.writeAll(name),
        .call => |call| {
            try writer.print("{s}(", .{call.name});
            for (call.args, 0..) |arg, i| {
                if (i > 0) try writer.writeAll(", ");
                try printExpr(writer, arg);
            }
            try writer.writeByte(')');
        },
        .binary => |binary| {
            try writer.writeByte('(');
            try printExpr(writer, binary.left);
            try writer.print(" {s} ", .{opText(binary.op)});
            try printExpr(writer, binary.right);
            try writer.writeByte(')');
        },
    }
}

fn printIndent(writer: anytype, indent: usize) !void {
    for (0..indent) |_| try writer.writeAll("  ");
}

fn opText(op: ast.BinaryOp) []const u8 {
    return switch (op) {
        .add => "+",
        .sub => "-",
        .mul => "*",
        .div => "/",
        .mod => "%",
        .eq => "==",
        .neq => "!=",
        .lt => "<",
        .lte => "<=",
        .gt => ">",
        .gte => ">=",
    };
}
