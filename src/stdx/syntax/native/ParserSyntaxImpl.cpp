/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

/*
 * @file
 *
 * This file implements the ParserSyntaxImpl.
 */

#include "ParserSyntaxImpl.h"

#include "cangjie/AST/Match.h"
#include "cangjie/Utils/Unicode.h"

using namespace Cangjie;
using namespace Cangjie::AST;

namespace StdxSyntax {
ParserSyntaxImpl::ParserSyntaxImpl(const std::string& input, DiagnosticEngine& diag, SourceManager& sm, const Position& pos,
    bool attachComment)
    : lexer{std::make_unique<Lexer>(input, diag, sm, pos, attachComment)}
{
    // no compile options here, keep local mode enabled as the parser does
    lexer->SetLocalModeEnabled(true);
}

ParserSyntaxImpl::ParserSyntaxImpl(const std::vector<Token>& inputTokens, DiagnosticEngine& diag, SourceManager& sm,
    bool attachComment)
    : lexer{std::make_unique<Lexer>(inputTokens, diag, sm, attachComment)}
{
    // no compile options here, keep local mode enabled as the parser does
    lexer->SetLocalModeEnabled(true);
}

ParserSyntaxImpl::~ParserSyntaxImpl()
{
}

const Token& ParserSyntaxImpl::Peek()
{
    if (lookahead.kind != TokenKind::SENTINEL) {
        return lookahead;
    }
    bool firstNLFlag = true;
    // skip comments, newlines (conditionally)
    // as part of this, also keep `bracketsStack` up-to-date
    do {
        lookahead = lexer->Next();
        if (calculateLineNum) {
            allTokensInOneFile.emplace_back(lookahead.Begin().line, lookahead.End().line);
        }
        if (lookahead.kind == TokenKind::LCURL || lookahead.kind == TokenKind::LPAREN ||
            lookahead.kind == TokenKind::LSQUARE) {
            bracketsStack.push_back(lookahead.kind);
        }
        const std::unordered_map<TokenKind, TokenKind> MATCHING_OPENING_BRACKET_OF{{TokenKind::RCURL, TokenKind::LCURL},
            {TokenKind::RSQUARE, TokenKind::LSQUARE}, {TokenKind::RPAREN, TokenKind::LPAREN}};
        auto matchingBracket = MATCHING_OPENING_BRACKET_OF.find(lookahead.kind);
        if (matchingBracket != MATCHING_OPENING_BRACKET_OF.end()) {
            if (!bracketsStack.empty() && matchingBracket->second == bracketsStack.back()) {
                bracketsStack.pop_back();
            }
        }
        if (lookahead.kind == TokenKind::NL) {
            newlineSkipped = true;
            if (firstNLFlag) {
                firstNLPosition = lookahead.Begin();
                firstNLFlag = false;
            }
        }
    } while (lookahead.kind == TokenKind::COMMENT || (lookahead.kind == TokenKind::NL && skipNL));
    // If reach end of file, the end pos should be adjacent with last non-comment token.
    if (lookahead.kind == TokenKind::END && !lastToken.Begin().IsZero()) {
        lookahead.SetValuePos(lookahead.Value(), lastToken.End(), lastToken.End());
    }
    return lookahead;
}

bool ParserSyntaxImpl::Seeing(const std::vector<TokenKind>& kinds, bool skipNewline)
{
    if (lookahead.kind != TokenKind::SENTINEL) {
        if (lookahead.kind == kinds[0]) {
            return lexer->Seeing(kinds.begin() + 1, kinds.end(), skipNewline);
        }
        return false;
    } else {
        return lexer->Seeing(kinds, skipNewline);
    }
}

bool ParserSyntaxImpl::SeeingModifier()
{
    return (Peek().kind >= TokenKind::STATIC && Peek().kind <= TokenKind::OPERATOR) ||
        (Peek().kind == TokenKind::CONST) || (Peek().kind == TokenKind::COMMON) || (Peek().kind == TokenKind::SPECIFIC);
}

bool ParserSyntaxImpl::SeeingMacroCall()
{
    if (!Seeing(TokenKind::AT)) {
        return false;
    }
    // Get annotation identifier.
    auto tokens = lexer->LookAheadSkipNL(1);
    if (tokens.begin()->kind != TokenKind::IDENTIFIER && (tokens.begin()->kind < TokenKind::PUBLIC ||
        tokens.begin()->kind > TokenKind::OPEN)) {
        return false;
    }
    return !IsBuiltinAnnotation(moduleName, tokens.begin()->Value());
}

bool ParserSyntaxImpl::SeeingBuiltinAnnotation()
{
    if (!Seeing(TokenKind::AT)) {
        return false;
    }
    // Get annotation identifier.
    auto tokens = lexer->LookAheadSkipNL(1);
    if (tokens.begin()->kind != TokenKind::IDENTIFIER) {
        return false;
    }
    return IsBuiltinAnnotation(moduleName, tokens.begin()->Value());
}

bool ParserSyntaxImpl::SeeingExpr()
{
    static const std::vector<TokenKind> exprFirstToken = {
        TokenKind::SUB,
        TokenKind::NOT,
        TokenKind::IF,
        TokenKind::MATCH,
        TokenKind::QUOTE,
        TokenKind::TRY,
        TokenKind::THROW,
        TokenKind::PERFORM,
        TokenKind::RESUME,
        TokenKind::RETURN,
        TokenKind::CONTINUE,
        TokenKind::BREAK,
        TokenKind::FOR,
        TokenKind::WHILE,
        TokenKind::DO,
        TokenKind::SPAWN,
        TokenKind::SYNCHRONIZED,
        TokenKind::LPAREN,
        TokenKind::LCURL,
        TokenKind::LSQUARE,
        TokenKind::THIS,
        TokenKind::SUPER,
        TokenKind::IDENTIFIER,
        TokenKind::UNSAFE,
        TokenKind::WILDCARD,
        TokenKind::VARRAY,
    };
    if (SeeingAny(exprFirstToken)) {
        return true;
    }
    return SeeingLiteral() || SeeingPrimitiveTypeAndLParen() || SeeingPrimitiveTypeAndDot() || SeeingMacroCall() ||
        SeeingBuiltinAnnotation();
}
} // namespace StdxSyntax
