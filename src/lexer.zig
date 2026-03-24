const std = @import("std");
const token_mod = @import("token.zig");
const Token = token_mod.Token;
const TokenType = token_mod.TokenType;

pub const Lexer = struct {
    source: []const u8,
    index: usize = 0,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Lexer {
        return .{ .allocator = allocator, .source = source };
    }

    pub fn tokenize(self: *Lexer) ![]Token {
        var tokens = std.ArrayList(Token).init(self.allocator);
        while (!self.isAtEnd()) {
            self.skipTrivia();
            if (self.isAtEnd()) break;
            try tokens.append(try self.nextToken());
        }
        try tokens.append(.{ .kind = .eof, .lexeme = "" });
        return tokens.toOwnedSlice();
    }

    fn nextToken(self: *Lexer) !Token {
        const ch = self.advance();
        switch (ch) {
            '(' => return .{ .kind = .l_paren, .lexeme = self.source[self.index - 1 .. self.index] },
            ')' => return .{ .kind = .r_paren, .lexeme = self.source[self.index - 1 .. self.index] },
            '{' => return .{ .kind = .l_brace, .lexeme = self.source[self.index - 1 .. self.index] },
            '}' => return .{ .kind = .r_brace, .lexeme = self.source[self.index - 1 .. self.index] },
            ',' => return .{ .kind = .comma, .lexeme = self.source[self.index - 1 .. self.index] },
            '+' => return .{ .kind = .plus, .lexeme = self.source[self.index - 1 .. self.index] },
            '-' => return .{ .kind = .minus, .lexeme = self.source[self.index - 1 .. self.index] },
            '*' => return .{ .kind = .star, .lexeme = self.source[self.index - 1 .. self.index] },
            '/' => return .{ .kind = .slash, .lexeme = self.source[self.index - 1 .. self.index] },
            '%' => return .{ .kind = .percent, .lexeme = self.source[self.index - 1 .. self.index] },
            '=' => {
                if (self.match('=')) return .{ .kind = .equal_equal, .lexeme = self.source[self.index - 2 .. self.index] };
                return .{ .kind = .assign, .lexeme = self.source[self.index - 1 .. self.index] };
            },
            '!' => {
                if (self.match('=')) return .{ .kind = .bang_equal, .lexeme = self.source[self.index - 2 .. self.index] };
                return error.UnexpectedCharacter;
            },
            ':' => {
                if (self.match('=')) return .{ .kind = .decl_assign, .lexeme = self.source[self.index - 2 .. self.index] };
                return error.UnexpectedCharacter;
            },
            '<' => {
                if (self.match('=')) return .{ .kind = .less_equal, .lexeme = self.source[self.index - 2 .. self.index] };
                return .{ .kind = .less, .lexeme = self.source[self.index - 1 .. self.index] };
            },
            '>' => {
                if (self.match('=')) return .{ .kind = .greater_equal, .lexeme = self.source[self.index - 2 .. self.index] };
                return .{ .kind = .greater, .lexeme = self.source[self.index - 1 .. self.index] };
            },
            else => {
                if (std.ascii.isDigit(ch)) return self.number();
                if (isIdentifierStart(ch)) return self.identifier();
                return error.UnexpectedCharacter;
            },
        }
    }

    fn number(self: *Lexer) !Token {
        const start = self.index - 1;
        while (!self.isAtEnd() and std.ascii.isDigit(self.peek())) _ = self.advance();

        if (!self.isAtEnd() and self.peek() == '.') {
            _ = self.advance();
            while (!self.isAtEnd() and std.ascii.isDigit(self.peek())) _ = self.advance();
        }

        const lexeme = self.source[start..self.index];
        return .{ .kind = .number, .lexeme = lexeme, .number = try std.fmt.parseFloat(f64, lexeme) };
    }

    fn identifier(self: *Lexer) !Token {
        const start = self.index - 1;
        while (!self.isAtEnd() and isIdentifierPart(self.peek())) _ = self.advance();
        const lexeme = self.source[start..self.index];
        return .{ .kind = token_mod.keywordType(lexeme) orelse .identifier, .lexeme = lexeme };
    }

    fn skipTrivia(self: *Lexer) void {
        while (!self.isAtEnd()) {
            const ch = self.peek();
            if (std.ascii.isWhitespace(ch)) {
                _ = self.advance();
                continue;
            }

            if (ch == '/' and self.peekNext() == '/') {
                while (!self.isAtEnd() and self.peek() != '\n') _ = self.advance();
                continue;
            }

            return;
        }
    }

    inline fn isAtEnd(self: *const Lexer) bool {
        return self.index >= self.source.len;
    }

    inline fn peek(self: *const Lexer) u8 {
        return self.source[self.index];
    }

    inline fn peekNext(self: *const Lexer) u8 {
        if (self.index + 1 >= self.source.len) return 0;
        return self.source[self.index + 1];
    }

    inline fn advance(self: *Lexer) u8 {
        const ch = self.source[self.index];
        self.index += 1;
        return ch;
    }

    fn match(self: *Lexer, expected: u8) bool {
        if (self.isAtEnd() or self.peek() != expected) return false;
        _ = self.advance();
        return true;
    }
};

fn isIdentifierStart(ch: u8) bool {
    return std.ascii.isAlphabetic(ch) or ch == '_';
}

fn isIdentifierPart(ch: u8) bool {
    return std.ascii.isAlphanumeric(ch) or ch == '_';
}
