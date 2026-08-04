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
 * This file declares the NodeWriter, which serializes AST for Syntax.
 */

#ifndef CANGJIE_NODE_WRITER_H
#define CANGJIE_NODE_WRITER_H

#include <cstdint>
#include <string>
#include <vector>

#include "flatbuffers/StdxSyntaxFormat_generated.h"
#include "cangjie/Basic/Print.h"
#include "cangjie/Basic/SourceManager.h"
#include "cangjie/AST/Node.h"
#include "cangjie/Basic/DiagnosticEmitter.h"
using namespace Cangjie;

using AstNode = Ptr<const Cangjie::AST::Node>;
using AstExpr = Ptr<const Cangjie::AST::Expr>;
using AstCallExpr = Ptr<const Cangjie::AST::CallExpr>;
using AstLambdaExpr = Ptr<const Cangjie::AST::LambdaExpr>;
using AstType = Ptr<const Cangjie::AST::Type>;
using AstRefType = Ptr<const Cangjie::AST::RefType>;
using AstRefExpr = Ptr<const Cangjie::AST::RefExpr>;
using AstPrimitiveType = Ptr<const Cangjie::AST::PrimitiveType>;
using AstAnnotation = Ptr<const Cangjie::AST::Annotation>;
using AstModifier = Ptr<const Cangjie::AST::Modifier>;
using AstDecl = Ptr<const Cangjie::AST::Decl>;
using AstVarDecl = Ptr<const Cangjie::AST::VarDecl>;
using AstMainDecl = Ptr<const Cangjie::AST::MainDecl>;
using AstFuncDecl = Ptr<const Cangjie::AST::FuncDecl>;
using AstMacroDecl = Ptr<const Cangjie::AST::MacroDecl>;
using AstMacroExpandDecl = Ptr<const Cangjie::AST::MacroExpandDecl>;
using AstFuncArg = Ptr<const Cangjie::AST::FuncArg>;
using AstFuncBody = Ptr<const Cangjie::AST::FuncBody>;
using AstFuncParam = Ptr<const Cangjie::AST::FuncParam>;
using AstMacroExpandParam = Ptr<const Cangjie::AST::MacroExpandParam>;
using AstBlock = Ptr<const Cangjie::AST::Block>;
using AstStructBody = Ptr<const Cangjie::AST::StructBody>;
using AstInterfaceBody = Ptr<const Cangjie::AST::InterfaceBody>;
using AstClassBody = Ptr<const Cangjie::AST::ClassBody>;
using AstGeneric = Ptr<const Cangjie::AST::Generic>;
using AstGenericParamDecl = Ptr<const Cangjie::AST::GenericParamDecl>;
using AstGenericConstraint = Ptr<const Cangjie::AST::GenericConstraint>;
using AstPattern = Ptr<const Cangjie::AST::Pattern>;
using AstEnumPattern = Ptr<const Cangjie::AST::EnumPattern>;
using AstMatchCase = Ptr<const Cangjie::AST::MatchCase>;
using AstMatchCaseOther = Ptr<const Cangjie::AST::MatchCaseOther>;
using AstFile = Ptr<const Cangjie::AST::File>;
using AstFeaturesDirective = Ptr<const Cangjie::AST::FeaturesDirective>;
using AstPackageSpec = Ptr<const Cangjie::AST::PackageSpec>;
using AstImportSpec = Ptr<const Cangjie::AST::ImportSpec>;
using AstCommentGroups = const Cangjie::AST::CommentGroups;
using AstCommentGroup = const Cangjie::AST::CommentGroup;
using AstComment = const Cangjie::AST::Comment;

using SyntaxFormatDecl = flatbuffers::Offset<SyntaxFormat::Decl>;
using SyntaxFormatExpr = flatbuffers::Offset<SyntaxFormat::Expr>;
using SyntaxFormatType = flatbuffers::Offset<SyntaxFormat::Type>;
using SyntaxFormatPattern = flatbuffers::Offset<SyntaxFormat::Pattern>;

namespace AstWriter {
const size_t INITIAL_FILE_SIZE = 65536;

using namespace Cangjie;
uint8_t* ExportDiags(const std::vector<DiagnosticInfo>& diags, flatbuffers::FlatBufferBuilder& builder);

class NodeWriter {
public:
    NodeWriter(Ptr<AST::Node> nodePtr) : nodePtr(nodePtr), builder(INITIAL_FILE_SIZE)
    {
    }
    ~NodeWriter()
    {
    }
    uint8_t* ExportNode(SourceManager* sm); // uint8_t* -> unsafePtr in CangJie
    bool isUnsupported = false;
private:
    std::vector<uint8_t> bufferData;
    Ptr<AST::Node> nodePtr = nullptr; // nodePtr is the AST node to be serialized
    flatbuffers::Offset<SyntaxFormat::DeclBase> emptyDeclBase = flatbuffers::Offset<SyntaxFormat::DeclBase>();
    flatbuffers::Offset<SyntaxFormat::NodeBase> emptyNodeBase = flatbuffers::Offset<SyntaxFormat::NodeBase>();
    flatbuffers::Offset<SyntaxFormat::TypeBase> emptyTypeBase = flatbuffers::Offset<SyntaxFormat::TypeBase>();
    template <typename K, typename U, typename V>
    flatbuffers::Offset<flatbuffers::Vector<flatbuffers::Offset<K>>> FlatVectorCreateHelper(
        const std::vector<OwnedPtr<U>>& input, flatbuffers::Offset<K> (NodeWriter::*funcPtr)(V));
    SyntaxFormat::Position FlatPosCreateHelper(const Position& pos) const;
    flatbuffers::Offset<flatbuffers::Vector<const SyntaxFormat::Position*>> CreatePositionVector(
        const std::vector<Cangjie::Position>& positions);
    flatbuffers::FlatBufferBuilder builder; // FlatBufferBuilder which contains the buffer it grows.
    flatbuffers::Offset<SyntaxFormat::MacroInvocation> MacroInvocationCreateHelper(
        const AST::MacroInvocation& macroInvocation);
    std::vector<flatbuffers::Offset<SyntaxFormat::Token>> TokensVectorCreateHelper(
        std::vector<Cangjie::Token> tokenVector);
    std::vector<flatbuffers::Offset<SyntaxFormat::CommentGroup>> CommentGroupVectorCreateHelper(
        std::vector<Cangjie::AST::CommentGroup> commentGroupVector);
    std::vector<flatbuffers::Offset<SyntaxFormat::Comment>> CommentVectorCreateHelper(
        std::vector<Cangjie::AST::Comment> commentVector);
    flatbuffers::Offset<SyntaxFormat::NodeBase> SerializeNodeBase(AstNode node, SourceManager* sm = nullptr);

    flatbuffers::Offset<SyntaxFormat::Pattern> SerializePattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeConstPattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeWildcardPattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeVarPattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeExceptTypePattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeCommandTypePattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeResumptionTypePattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeTypePattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeEnumPattern(const AST::Pattern* pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeMultiEnumPattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeVarOrEnumPattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::Pattern> SerializeTuplePattern(AstPattern pattern);
    flatbuffers::Offset<SyntaxFormat::EnumPattern> SerializeEnumPattern(const AST::EnumPattern* enumPattern);
    flatbuffers::Offset<SyntaxFormat::MatchCase> SerializeMatchCase(AstMatchCase matchcase);
    flatbuffers::Offset<SyntaxFormat::MatchCaseOther> SerializeMatchCaseOther(AstMatchCaseOther matchcaseother);

    flatbuffers::Offset<SyntaxFormat::Expr> SerializeExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeWildcardExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeBinaryExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeIsExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeAsExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeLitConstExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeInterpolationExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeUnaryExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeParenExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeCallExpr(const AST::Expr* expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeRefExpr(const AST::Expr* expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeReturnExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeAssignExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeMemberAccess(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeLambdaExpr(const AST::Expr* expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeTrailingClosureExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeTypeConvExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeTryExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeMatchExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeTokenPart(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeQuoteExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeThrowExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializePerformExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeResumeExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeForInExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeIfExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeLetPatternDestructor(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeBlockExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeWhileExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeDoWhileExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeJumpExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeIncOrDecExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializePrimitiveTypeExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeSpawnExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeSynchronizedExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeArrayLit(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeTupleLit(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeSubscriptExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeRangeExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::CallExpr> SerializeCallExpr(const AST::CallExpr* callExpr);
    flatbuffers::Offset<SyntaxFormat::LambdaExpr> SerializeLambdaExpr(const AST::LambdaExpr* lambdaExpr);
    flatbuffers::Offset<SyntaxFormat::Block> SerializeBlock(AstBlock block);
    flatbuffers::Offset<SyntaxFormat::FuncArg> SerializeFuncArg(AstFuncArg funcArg);
    flatbuffers::Offset<SyntaxFormat::RefExpr> SerializeRefExpr(const AST::RefExpr* refExpr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeOptionalExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeOptionalChainExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeMacroExpandExpr(AstExpr expr);
    flatbuffers::Offset<SyntaxFormat::Expr> SerializeArrayExpr(AstExpr expr);

    flatbuffers::Offset<SyntaxFormat::TypeBase> SerializeTypeBase(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeRefType(const AST::Type* type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializePrimitiveType(const AST::Type* type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeArrayType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeFuncType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeThisType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeParenType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeQualifiedType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeOptionType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeTupleType(AstType type);
    flatbuffers::Offset<SyntaxFormat::RefType> SerializeRefType(const AST::RefType* refType);
    flatbuffers::Offset<SyntaxFormat::PrimitiveType> SerializePrimitiveType(const AST::PrimitiveType* primitiveType);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeVArrayType(AstType type);
    flatbuffers::Offset<SyntaxFormat::Type> SerializeConstantType(AstType type);

    flatbuffers::Offset<SyntaxFormat::Annotation> SerializeAnnotation(AstAnnotation annotation);
    flatbuffers::Offset<SyntaxFormat::Modifier> SerializeModifier(AstModifier modifier);
    flatbuffers::Offset<SyntaxFormat::DeclBase> SerializeDeclBase(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeVarWithPatternDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeVarDecl(const AST::Decl* decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeMainDecl(const AST::Decl* decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeFuncDecl(const AST::Decl* decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeMacroDecl(const AST::Decl* decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeMacroExpandDecl(const AST::Decl* decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeStructDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializePropDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeTypeAliasDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeExtendDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeClassDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeInterfaceDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeEnumDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializePrimaryCtorDecl(AstDecl decl);
    flatbuffers::Offset<SyntaxFormat::VarDecl> SerializeVarDecl(const AST::VarDecl* varDecl);
    flatbuffers::Offset<SyntaxFormat::MainDecl> SerializeMainDecl(const AST::MainDecl* mainDecl);
    flatbuffers::Offset<SyntaxFormat::FuncDecl> SerializeFuncDecl(const AST::FuncDecl* funcDecl);
    flatbuffers::Offset<SyntaxFormat::MacroDecl> SerializeMacroDecl(const AST::MacroDecl* macroDecl);
    flatbuffers::Offset<SyntaxFormat::MacroExpandDecl> SerializeMacroExpandDecl(
        const AST::MacroExpandDecl* macroExpandDecl);
    flatbuffers::Offset<SyntaxFormat::Decl> SerializeDeclOfFuncParam(const AST::Decl* decl);
    flatbuffers::Offset<SyntaxFormat::FuncBody> SerializeFuncBody(AstFuncBody funcBody);
    flatbuffers::Offset<SyntaxFormat::FuncParam> SerializeFuncParam(AstFuncParam funcParam);
    flatbuffers::Offset<SyntaxFormat::FuncParam> SerializeMacroExpandParam(AstMacroExpandParam mep);
    flatbuffers::Offset<SyntaxFormat::StructBody> SerializeStructBody(AstStructBody structBody);
    flatbuffers::Offset<SyntaxFormat::InterfaceBody> SerializeInterfaceBody(AstInterfaceBody interfaceBody);
    flatbuffers::Offset<SyntaxFormat::ClassBody> SerializeClassBody(AstClassBody classBody);
    flatbuffers::Offset<SyntaxFormat::Generic> SerializeGeneric(AstGeneric generic);
    flatbuffers::Offset<SyntaxFormat::GenericParamDecl> SerializeGenericParamDecl(AstGenericParamDecl genericParamDecl);
    flatbuffers::Offset<SyntaxFormat::GenericConstraint> SerializeGenericConstraint(
        AstGenericConstraint genericConstraint);

    flatbuffers::Offset<SyntaxFormat::File> SerializeFile(AstFile file, SourceManager* sm = nullptr);
    flatbuffers::Offset<SyntaxFormat::ImportSpec> SerializeImportSpec(AstImportSpec importSpec);
    flatbuffers::Offset<SyntaxFormat::ImportContent> SerializeImportContent(const AST::ImportContent& content);
    flatbuffers::Offset<SyntaxFormat::PackageSpec> SerializePackageSpec(AstPackageSpec packageSpec);
    flatbuffers::Offset<SyntaxFormat::FeaturesDirective> SerializeFeaturesDirective(AstFeaturesDirective featureDirective);
    flatbuffers::Offset<SyntaxFormat::FeaturesSet> SerializeFeaturesSet(const AST::FeaturesSet& fSet);
    flatbuffers::Offset<SyntaxFormat::FeatureId> SerializeFeatureId(const AST::FeatureId& featureId);
    flatbuffers::Offset<SyntaxFormat::CommentGroups> SerializeCommentGroups(AstCommentGroups comments);
    flatbuffers::Offset<SyntaxFormat::CommentGroup> SerializeCommentGroup(AstCommentGroup commentGroup);
    flatbuffers::Offset<SyntaxFormat::Comment> SerializeComment(AstComment comment);
};

template <typename K, typename U, typename V>
flatbuffers::Offset<flatbuffers::Vector<flatbuffers::Offset<K>>> NodeWriter::FlatVectorCreateHelper(
    const std::vector<OwnedPtr<U>>& input, flatbuffers::Offset<K> (NodeWriter::*funcPtr)(V))
{
    std::vector<flatbuffers::Offset<K>> vecK;
    for (auto& ele : input) {
        auto fbK = std::invoke(funcPtr, this, ele.get());
        vecK.push_back(fbK);
    }
    return builder.CreateVector(vecK);
}

} // namespace AstWriter
#endif // CANGJIE_NODE_WRITER_H
