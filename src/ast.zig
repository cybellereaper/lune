const std = @import("std");

pub const BinaryOp = enum {
    add,
    sub,
    mul,
    div,
    mod,
    eq,
    neq,
    lt,
    lte,
    gt,
    gte,
};

pub const Expr = union(enum) {
    number: f64,
    boolean: bool,
    variable: []const u8,
    binary: struct { op: BinaryOp, left: *Expr, right: *Expr },
    call: struct { name: []const u8, args: []*Expr },
};

pub const Stmt = union(enum) {
    var_decl: struct { name: []const u8, value: *Expr },
    assign: struct { name: []const u8, value: *Expr },
    return_stmt: ?*Expr,
    if_stmt: struct { condition: *Expr, then_block: []Stmt, else_block: []Stmt },
    while_stmt: struct { condition: *Expr, body: []Stmt },
    expr_stmt: *Expr,
};

pub const FunctionDecl = struct {
    name: []const u8,
    params: []const []const u8,
    body: []Stmt,
};

pub const ConstDecl = struct {
    name: []const u8,
    value: *Expr,
};

pub const Item = union(enum) {
    const_decl: ConstDecl,
    function_decl: FunctionDecl,
};

pub const Program = struct {
    items: []Item,
};
