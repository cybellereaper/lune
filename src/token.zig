const std = @import("std");

pub const TokenType = enum {
    eof,
    identifier,
    number,
    kw_const,
    kw_fn,
    kw_return,
    kw_if,
    kw_else,
    kw_while,
    kw_true,
    kw_false,
    l_paren,
    r_paren,
    l_brace,
    r_brace,
    comma,
    plus,
    minus,
    star,
    slash,
    percent,
    assign,
    decl_assign,
    equal_equal,
    bang_equal,
    less,
    less_equal,
    greater,
    greater_equal,
};

pub const Token = struct {
    kind: TokenType,
    lexeme: []const u8,
    number: ?f64 = null,

    pub fn is(self: Token, kind: TokenType) bool {
        return self.kind == kind;
    }
};

pub fn keywordType(lexeme: []const u8) ?TokenType {
    if (std.mem.eql(u8, lexeme, "const")) return .kw_const;
    if (std.mem.eql(u8, lexeme, "fn")) return .kw_fn;
    if (std.mem.eql(u8, lexeme, "return")) return .kw_return;
    if (std.mem.eql(u8, lexeme, "if")) return .kw_if;
    if (std.mem.eql(u8, lexeme, "else")) return .kw_else;
    if (std.mem.eql(u8, lexeme, "while")) return .kw_while;
    if (std.mem.eql(u8, lexeme, "true")) return .kw_true;
    if (std.mem.eql(u8, lexeme, "false")) return .kw_false;
    return null;
}
