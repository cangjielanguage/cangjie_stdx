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
 * This file implements the ParserSyntax.
 */

#include "ParserSyntax.h"
#include "ParserSyntaxImpl.h"

#include "cangjie/AST/Clone.h"
#include "cangjie/AST/Create.h"
#include "cangjie/AST/Match.h"
#include "cangjie/AST/Node.h"
#include "cangjie/AST/Utils.h"
#include "cangjie/AST/Walker.h"
#include "cangjie/Lex/Token.h"
#include "cangjie/Utils/FileUtil.h"
#include "cangjie/Utils/Utils.h"

using namespace Cangjie;
using namespace Cangjie::AST;

namespace StdxSyntax {
ParserSyntax::ParserSyntax(const std::string& input, DiagnosticEngine& diag, SourceManager& sm, const Position& pos,
    bool attachComment)
    : Parser(input, diag, sm, pos, attachComment, nullptr),
      implSyntax(std::make_unique<ParserSyntaxImpl>(input, diag, sm, pos, attachComment))
{
}

ParserSyntax::ParserSyntax(const std::vector<Token>& inputTokens, DiagnosticEngine& diag, SourceManager& sm, bool attachComment)
    : Parser(inputTokens, diag, sm, attachComment, nullptr),
      implSyntax(std::make_unique<ParserSyntaxImpl>(inputTokens, diag, sm, attachComment))
{
}

ParserSyntax::~ParserSyntax()
{
}

OwnedPtr<AST::Node> ParserSyntax::ParseExprOrDecl(ScopeKind sk)
{
    if (implSyntax->SeeingMacroCall()) {
        return nullptr;
    } else if (implSyntax->Seeing(TokenKind::AT_EXCL) || implSyntax->SeeingDecl() || implSyntax->Seeing({TokenKind::BITNOT, TokenKind::INIT}, false)) {
        return ParseDecl(sk);
    } else if (implSyntax->SeeingExpr()) {
        return ParseExpr();
    }
    return nullptr;
}

void ParserSyntax::AttachComment(std::vector<OwnedPtr<AST::Node>>& nodes)
{
    AttachCommentToNodes(nodes);
}
} // namespace StdxSyntax
