#include "lune/pretty_printer.hpp"

#include <sstream>
#include <string>

namespace lune {
namespace {

std::string quote_string(const std::string& value) {
    std::string quoted;
    quoted.push_back('"');
    for (const char c : value) {
        if (c == '"' || c == '\\') {
            quoted.push_back('\\');
        }
        quoted.push_back(c);
    }
    quoted.push_back('"');
    return quoted;
}

class PrettyPrinter {
public:
    std::string print(const Program& program) {
        print_statement_list(program.items, 0);
        return out_.str();
    }

private:
    std::string print_expr(const ExprPtr& expr) {
        return std::visit([this](const auto& node) { return print_expr_node(node); }, expr->node);
    }

    std::string print_expr_node(const NumberExpr& expr) {
        std::ostringstream num;
        num << expr.value;
        return num.str();
    }

    std::string print_expr_node(const BoolExpr& expr) { return expr.value ? "true" : "false"; }

    std::string print_expr_node(const NullExpr&) { return "null"; }

    std::string print_expr_node(const StringExpr& expr) { return quote_string(expr.value); }

    std::string print_expr_node(const IdentifierExpr& expr) { return expr.name; }

    std::string print_expr_node(const BinaryExpr& expr) {
        return "(" + print_expr(expr.lhs) + " " + expr.op + " " + print_expr(expr.rhs) + ")";
    }

    std::string print_expr_node(const CallExpr& expr) {
        std::string rendered = expr.callee + "(";
        for (std::size_t i = 0; i < expr.args.size(); ++i) {
            if (i > 0) rendered += ", ";
            rendered += print_expr(expr.args[i]);
        }
        rendered += ")";
        return rendered;
    }

    std::string print_expr_node(const IfExpr& expr) {
        std::string rendered = "if " + print_expr(expr.condition) + " ";
        rendered += render_inline_block(expr.then_branch);
        if (!expr.else_branch.empty()) {
            rendered += " else ";
            rendered += render_inline_block(expr.else_branch);
        }
        return rendered;
    }

    std::string render_inline_block(const std::vector<StmtPtr>& statements) {
        std::ostringstream block;
        block << "{";
        if (!statements.empty()) {
            block << "\n";
            print_statement_list(statements, 1, block);
        }
        block << "}";
        return block.str();
    }

    void print_statement_list(const std::vector<StmtPtr>& statements, std::size_t indent, std::ostringstream& target) {
        for (std::size_t i = 0; i < statements.size(); ++i) {
            print_indent(indent, target);
            print_statement(statements[i], indent, target);
            if (i + 1 < statements.size()) {
                target << "\n";
            }
        }
    }

    void print_statement_list(const std::vector<StmtPtr>& statements, std::size_t indent) {
        print_statement_list(statements, indent, out_);
    }

    void print_indent(std::size_t indent, std::ostringstream& target) {
        for (std::size_t i = 0; i < indent; ++i) {
            target << "  ";
        }
    }

    void print_statement(const StmtPtr& stmt, std::size_t indent, std::ostringstream& target) {
        std::visit([&](const auto& node) { print_stmt_node(node, indent, target); }, stmt->node);
    }

    void print_stmt_node(const ExprStmt& stmt, std::size_t, std::ostringstream& target) { target << print_expr(stmt.expr); }

    void print_stmt_node(const ConstDeclStmt& stmt, std::size_t, std::ostringstream& target) {
        target << "const " << stmt.name << " = " << print_expr(stmt.expr);
    }

    void print_stmt_node(const ShortDeclStmt& stmt, std::size_t, std::ostringstream& target) {
        target << stmt.name << " := " << print_expr(stmt.expr);
    }

    void print_stmt_node(const AssignStmt& stmt, std::size_t, std::ostringstream& target) {
        target << stmt.name << " = " << print_expr(stmt.expr);
    }

    void print_stmt_node(const ReturnStmt& stmt, std::size_t, std::ostringstream& target) {
        target << "return";
        if (stmt.expr.has_value()) {
            target << " " << print_expr(stmt.expr.value());
        }
    }

    void print_stmt_node(const IfStmt& stmt, std::size_t indent, std::ostringstream& target) {
        target << "if " << print_expr(stmt.condition) << " {\n";
        print_statement_list(stmt.then_branch.statements, indent + 1, target);
        target << "\n";
        print_indent(indent, target);
        target << "}";
        if (stmt.else_branch.has_value()) {
            target << " else {\n";
            print_statement_list(stmt.else_branch->statements, indent + 1, target);
            target << "\n";
            print_indent(indent, target);
            target << "}";
        }
    }


    void print_stmt_node(const WhileStmt& stmt, std::size_t indent, std::ostringstream& target) {
        target << "while " << print_expr(stmt.condition) << " {\n";
        print_statement_list(stmt.body.statements, indent + 1, target);
        target << "\n";
        print_indent(indent, target);
        target << "}";
    }

    void print_stmt_node(const FunctionDecl& stmt, std::size_t indent, std::ostringstream& target) {
        target << "fn " << stmt.name << "(";
        for (std::size_t i = 0; i < stmt.params.size(); ++i) {
            if (i > 0) target << ", ";
            target << stmt.params[i];
        }
        target << ") {\n";
        print_statement_list(stmt.body.statements, indent + 1, target);
        target << "\n";
        print_indent(indent, target);
        target << "}";
    }

    void print_stmt_node(const BlockStmt& stmt, std::size_t indent, std::ostringstream& target) {
        target << "{\n";
        print_statement_list(stmt.statements, indent + 1, target);
        target << "\n";
        print_indent(indent, target);
        target << "}";
    }

    std::ostringstream out_;
};

} // namespace

std::string pretty_print(const Program& program) {
    PrettyPrinter printer;
    return printer.print(program);
}

} // namespace lune
