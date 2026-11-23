/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

/**
 * @file
 *
 * This file declares class ParserSyntaxImpl.
 */

#ifndef CANGJIE_PARSER_SYNTAX_IMPL_H
#define CANGJIE_PARSER_SYNTAX_IMPL_H

#include "cangjie/Parse/Parser.h"

using namespace Cangjie;
using namespace Cangjie::AST;

namespace StdxSyntax {
// Lexer takes no compile options here; follow the platform parser behavior:
// local mode is always enabled except on OHOS where it is always disabled.
// Keep in sync with ParserImpl::IsLocalModeEnabled
// (cangjie_compiler/src/Parse/ParserImpl.h), which defines this rule for
// the no-compile-options case.
// __ohos__ is defined globally by build/common/ohos_*_clang_toolchain.cmake;
// build paths that do not use those toolchain files must define it themselves.
inline void SetDefaultLocalModeEnabled(Lexer& lexer)
{
#ifdef __ohos__
    lexer.SetLocalModeEnabled(false);
#else
    lexer.SetLocalModeEnabled(true);
#endif
}

class ParserSyntaxImpl final {
public:

    ParserSyntaxImpl(const std::string& input, DiagnosticEngine& diag, SourceManager& sm, const Position& pos,
        bool attachComment);
    ParserSyntaxImpl(const std::vector<Token>& inputTokens, DiagnosticEngine& diag, SourceManager& sm, bool attachComment);
    ~ParserSyntaxImpl();

    Token lookahead{TokenKind::SENTINEL, "", Position(0, 1, 1), Position(0, 1, 1)}; /**< Current scanned token. */
    Token lastToken{TokenKind::SENTINEL, "", Position(0, 1, 1), Position(0, 1, 1)}; /**< Last scanned token. */

    // Peek next token, save it to lookAhead
    const Token& Peek();

    // Whether the next token is the given token kind.
    bool Seeing(TokenKind kind)
    {
        return Peek().kind == kind;
    }
    inline bool Seeing(TokenKind rangeLeft, TokenKind rangeRight)
    {
        return Peek().kind >= rangeLeft && Peek().kind <= rangeRight;
    }
    inline bool SeeingAny(const std::vector<TokenKind>& kinds)
    {
        return Utils::In(Peek().kind, kinds);
    }
    // Whether the following tokens are the given token vector. 'skipNL=true' means NL token should be skipped when scan
    // following tokens.
    bool Seeing(const std::vector<TokenKind>& kinds, bool skipNewline = true);
    bool SeeingMacroCall();
    bool SeeingBuiltinAnnotation();
    inline bool SeeingAnnotationLambdaExpr()
    {
        return Seeing({TokenKind::AT, TokenKind::IDENTIFIER, TokenKind::LCURL}) && SeeingBuiltinAnnotation();
    }
    // modifiers
    bool SeeingModifier();
    bool SeeingDecl()
    {
        if (SeeingIfAvailable()) {
            return false;
        }
        return (SeeingModifier() && !Seeing({TokenKind::UNSAFE, TokenKind::LCURL})) ||
            SeeingAny({TokenKind::FUNC, TokenKind::LET, TokenKind::VAR, TokenKind::ENUM, TokenKind::TYPE,
                TokenKind::STRUCT, TokenKind::CLASS, TokenKind::INTERFACE, TokenKind::MAIN, TokenKind::EXTEND, TokenKind::PROP}) ||
            (SeeingBuiltinAnnotation() && !SeeingAnnotationLambdaExpr());
    }
    /// Seeing IfAvailable Expr
    bool SeeingIfAvailable()
    {
        if (!Seeing(TokenKind::AT)) {
            return false;
        }
        // Get annotation identifier.
        auto tokens = lexer->LookAheadSkipNL(1);
        return !tokens.empty() && tokens.begin()->kind == TokenKind::IDENTIFIER &&
            tokens.begin()->Value() == IF_AVAILABLE;
    }
    bool SeeingExpr();
    bool SeeingLiteral()
    {
        return SeeingAny({TokenKind::INTEGER_LITERAL, TokenKind::RUNE_BYTE_LITERAL, TokenKind::BOOL_LITERAL,
            TokenKind::STRING_LITERAL, TokenKind::JSTRING_LITERAL, TokenKind::MULTILINE_STRING,
            TokenKind::MULTILINE_RAW_STRING, TokenKind::RUNE_LITERAL, TokenKind::FLOAT_LITERAL,
            TokenKind::UNIT_LITERAL});
    }
    bool SeeingPrimitiveTypeAndLParen()
    {
        return Seeing({TokenKind::INT8, TokenKind::LPAREN}) || Seeing({TokenKind::INT16, TokenKind::LPAREN}) ||
            Seeing({TokenKind::INT32, TokenKind::LPAREN}) || Seeing({TokenKind::INT64, TokenKind::LPAREN}) ||
            Seeing({TokenKind::INTNATIVE, TokenKind::LPAREN}) || Seeing({TokenKind::UINT8, TokenKind::LPAREN}) ||
            Seeing({TokenKind::UINT16, TokenKind::LPAREN}) || Seeing({TokenKind::UINT32, TokenKind::LPAREN}) ||
            Seeing({TokenKind::UINT64, TokenKind::LPAREN}) || Seeing({TokenKind::UINTNATIVE, TokenKind::LPAREN}) ||
            Seeing({TokenKind::FLOAT16, TokenKind::LPAREN}) || Seeing({TokenKind::FLOAT32, TokenKind::LPAREN}) ||
            Seeing({TokenKind::FLOAT64, TokenKind::LPAREN}) || Seeing({TokenKind::RUNE, TokenKind::LPAREN});
    }
    bool SeeingPrimitiveTypeAndDot()
    {
        return Seeing({TokenKind::INT8, TokenKind::DOT}) || Seeing({TokenKind::INT16, TokenKind::DOT}) ||
            Seeing({TokenKind::INT32, TokenKind::DOT}) || Seeing({TokenKind::INT64, TokenKind::DOT}) ||
            Seeing({TokenKind::INTNATIVE, TokenKind::DOT}) || Seeing({TokenKind::UINT8, TokenKind::DOT}) ||
            Seeing({TokenKind::UINT16, TokenKind::DOT}) || Seeing({TokenKind::UINT32, TokenKind::DOT}) ||
            Seeing({TokenKind::UINT64, TokenKind::DOT}) || Seeing({TokenKind::UINTNATIVE, TokenKind::DOT}) ||
            Seeing({TokenKind::FLOAT16, TokenKind::DOT}) || Seeing({TokenKind::FLOAT32, TokenKind::DOT}) ||
            Seeing({TokenKind::FLOAT64, TokenKind::DOT}) || Seeing({TokenKind::RUNE, TokenKind::DOT}) ||
            Seeing({TokenKind::BOOLEAN, TokenKind::DOT}) || Seeing({TokenKind::UNIT, TokenKind::DOT}) ||
            Seeing({TokenKind::NOTHING, TokenKind::DOT});
    }

    OwnedPtr<AST::Node> ParseExprOrDecl(ScopeKind sk);

private:
    std::unique_ptr<Lexer> lexer;
    std::string moduleName;
    bool calculateLineNum{false};
    // we store line number info from all tokens
    // pair<line num of the begin, line num of the end>
    std::list<std::pair<unsigned, unsigned>> allTokensInOneFile;
    std::vector<TokenKind> bracketsStack; /* A stack to help match brackets. */
    bool newlineSkipped{true};                  /**< Mark that a new line token has been skipped. */
    bool skipNL{true};                          /**< Skip new line token by default. */
    Position firstNLPosition{DEFAULT_POSITION}; /**< Record first nl position. */
};
} // namespace StdxSyntax

#endif // CANGJIE_PARSER_SYNTAX_IMPL_H