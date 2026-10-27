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
 * Runtime for manipulating Cangjie AST in libast.
 */

#include "AstApi.h"
#include "NodeWriter.h"
#include "TokenWriter.h" 
#include "ParserSyntax.h"
#include "cangjie/Basic/DiagnosticEmitter.h"
#include "cangjie/Basic/SourceManager.h"
#include "cangjie/Frontend/CompilerInstance.h"

#include "cangjie/Parse/Parser.h"
#include "cangjie/Macro/MacroCommon.h"
#include "cangjie/Macro/TokenSerialization.h"
#include "cangjie/Utils/FileUtil.h"
#include "cangjie/Basic/StringConvertor.h"

using namespace Cangjie;
using StdxSyntax::ParseRes;
using StdxSyntax::ParserSyntax;
namespace {
uint8_t* getDiagInfos(DiagnosticEngine& diag) {
    std::vector<DiagnosticInfo> diagInfosParse, diagInfosLex, diagInfos;
    diag.GetCategoryDiagnosticInfos(DiagCategory::PARSE, diagInfosParse);
    diag.GetCategoryDiagnosticInfos(DiagCategory::LEX, diagInfosLex);
    diagInfos = diagInfosParse;
    diagInfos.insert(diagInfos.end(), diagInfosLex.begin(), diagInfosLex.end());
    flatbuffers::FlatBufferBuilder builder(AstWriter::INITIAL_FILE_SIZE);
    return AstWriter::ExportDiags(diagInfos, builder);
}

void SetDiagEngine(DiagnosticEngine& diag, SourceManager& sm) {
    diag.SetSourceManager(&sm);
    diag.SetDiagnoseStatus(true);
    diag.DisableScopeCheck();
    diag.SetErrorCountLimit(std::nullopt);
    diag.EnableCheckRangeErrorCodeRatherICE();
}

ParseRes* createParseResult() {
    ParseRes* result = (ParseRes*)malloc(sizeof(ParseRes));
    if (result == nullptr) {
        return nullptr;
    }
    result->eMsg = nullptr;
    result->node = nullptr;
    return result;
}

ParseRes* getParseResult(ParseRes* result, DiagnosticEngine& diag, SourceManager& sm, Ptr<AST::Node> nodePtr) {
    if (result == nullptr) {
        return nullptr;
    }
    // Analyzing Errors and Warnings
    if (diag.GetErrorCount() || diag.GetWarningCount()) {
        result->eMsg = getDiagInfos(diag);
    }

    AstWriter::NodeWriter nodeWriter(nodePtr);
    if (diag.GetErrorCount() == 0 || nodeWriter.isUnsupported) {
        // Serialize ast node
        result->node = nodeWriter.ExportNode(&sm);
    }
    return result;
}

std::vector<Token> tokensFormatter(const uint8_t* tokensBytes)
{
    if (tokensBytes == nullptr) {
        return {};
    }
    std::vector<Token> oldTokens = TokenSerialization::GetTokensFromBytes(tokensBytes);
    std::vector<Position> escapePosVec = {};
    MacroFormatter formatter = MacroFormatter(oldTokens, escapePosVec, 1);
    auto tokenStr = formatter.Produce(false);
    DiagnosticEngine diag;
    SourceManager sm;
    Lexer lex(tokenStr, diag, sm, false, false);
    // no compile options here, keep local mode enabled as the parser does
    lex.SetLocalModeEnabled(true);
    std::vector<Token> tokens{};
    Token token = lex.Next();

    auto pos = token.Begin();
    auto end = token.End();
    auto inMacCall = false;

    while (token.kind != TokenKind::END) {
        auto tk = Token(token.kind, token.Value(), pos, end);
        tk.isSingleQuote = token.isSingleQuote;
        tk.delimiterNum = token.delimiterNum;
        tokens.emplace_back(tk);
        token = lex.Next();
        if (!inMacCall) {
            pos = token.Begin();
            end = token.End();
        }
    }
    tokens.emplace_back(token.kind, token.Value(), pos, end);
    return tokens;
}
} // namespace

extern "C" {
ParseRes* CJ_ParseFile(const char* path)
{
    if (path == nullptr) {
        return nullptr;
    }
    Cangjie::ICE::TriggerPointSetter iceSetter(CompileStage::PARSE);
    DiagnosticEngine diag;
    SourceManager sm;

    SetDiagEngine(diag, sm);
    std::string filePath(path, path + strlen(path));
    std::string failedReason;
#ifdef _WIN32
    // On Windows, detect encoding and convert to GBK for file system operations if needed
    const char* pathToUse = path;
    std::optional<std::string> gbkPathOpt;
    auto encoding = StringConvertor::GetStringEncoding(filePath);
    if (encoding == StringConvertor::UTF8) {
        gbkPathOpt = StringConvertor::UTF8ToGBK(filePath);
    } else if (encoding == StringConvertor::GBK) {
        gbkPathOpt = filePath;
    }
    if (gbkPathOpt.has_value()) {
        pathToUse = gbkPathOpt.value().c_str();
    }
    auto content = FileUtil::ReadFileContent(pathToUse, failedReason);
#else
    auto content = FileUtil::ReadFileContent(path, failedReason);
#endif

    if (!content.has_value()) {
        ParseRes* errorRes = createParseResult();
        return errorRes;
    }
    auto fileID = sm.AddSource(filePath, content.value());
    Parser parser(fileID, content.value(), diag, sm, true);
    auto file = parser.ParseTopLevel();
    ParseRes* res = createParseResult();
    return getParseResult(res, diag, sm, file.get());
}

ParseRes* CJ_ParseText(const char* text)
{
    if (text == nullptr) {
        return nullptr;
    }
    Cangjie::ICE::TriggerPointSetter iceSetter(CompileStage::PARSE);
    DiagnosticEngine diag;
    SourceManager sm;

    SetDiagEngine(diag, sm);
    std::string rawString(text, text + strlen(text));
    ParserSyntax parser(rawString, diag, sm, {0, 1, 1}, true);

    auto textParsed = parser.ParseExprOrDecl(ScopeKind::UNKNOWN_SCOPE);

    ParseRes* res = createParseResult();
    if (textParsed == nullptr) {
        return res;
    }

    std::vector<OwnedPtr<AST::Node>> nodes;
    nodes.emplace_back(std::move(textParsed));
    parser.AttachComment(nodes);
    return getParseResult(res, diag, sm, nodes[0].get());
}

ParseRes* CJ_ParseTokens(const uint8_t* tokensBytes, int64_t* tokenCounter, bool refreshPos)
{
    if (tokensBytes == nullptr) {
        return nullptr;
    }
    Cangjie::ICE::TriggerPointSetter iceSetter(CompileStage::PARSE);
    DiagnosticEngine diag;
    SourceManager sm;
    std::vector<Token> tokens = refreshPos ? tokensFormatter(tokensBytes) : TokenSerialization::GetTokensFromBytes(tokensBytes);

    SetDiagEngine(diag, sm);
    ParserSyntax parser(tokens, diag, sm, true);

    auto tokensParsed = parser.ParseExprOrDecl(ScopeKind::UNKNOWN_SCOPE);
    ParseRes* res = createParseResult();
    if (tokensParsed == nullptr) {
        return res;
    }
    if (tokenCounter != nullptr && static_cast<uint64_t>(parser.GetProcessedTokens()) != tokens.size()) {
        *tokenCounter = 1;
    }
    std::vector<OwnedPtr<AST::Node>> nodes;
    nodes.emplace_back(std::move(tokensParsed));
    parser.AttachComment(nodes);
    return getParseResult(res, diag, sm, nodes[0].get());
}

ParseRes* CJ_ParseAnnotationArguments(const uint8_t* tokensBytes)
{
    if (tokensBytes == nullptr) {
        return nullptr;
    }
    Cangjie::ICE::TriggerPointSetter iceSetter(CompileStage::PARSE);
    std::vector<Token> tokens = TokenSerialization::GetTokensFromBytes(tokensBytes);
    DiagnosticEngine diag;
    SourceManager sm;
    diag.SetSourceManager(&sm);
    diag.SetDiagnoseStatus(true);
    diag.DisableScopeCheck();
    diag.SetDisableWarning(true);
    diag.EnableCheckRangeErrorCodeRatherICE();
    Parser parser(tokens, diag, sm, false);
    auto node = parser.ParseCustomAnnotation();

    ParseRes* result = (ParseRes*)malloc(sizeof(ParseRes));
    // result free on cangjie side
    if (result == nullptr) {
        return nullptr;
    }
    AstWriter::NodeWriter nodeWriter(node.get());
    result->node = nodeWriter.ExportNode(&sm);
    result->eMsg = nullptr;
    return result;
}

void CJ_CheckAddSpaces(const uint8_t* tokBytes, bool* spaceFlag)
{
    if (tokBytes == nullptr) {
        return;
    }
    std::vector<Token> tokens = TokenSerialization::GetTokensFromBytes(tokBytes);
    if ((tokens.size() == 0)) {
        return;
    }
    for (size_t loop = 0; loop < tokens.size() - 1; loop++) {
        spaceFlag[loop] = CheckAddSpace(tokens[loop], tokens[loop + 1]);
    }
    spaceFlag[tokens.size() - 1] = false;
}

bool CJ_CheckIdentifier(const char* str, bool useContextualKeyWords) {
    if (!str) return false;
    return FileUtil::IsIdentifier(std::string(str), useContextualKeyWords);
}
}
