// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// This source file is part of the Cangjie project, licensed under Apache-2.0
// with Runtime Library Exception.
//
// See https://cangjie-lang.cn/pages/LICENSE for license information.

/*
 * @file
 *
 * This file implements the NodeWriter.
 */

#include "cangjie/AST/Match.h"
#include "cangjie/AST/Utils.h"
#include "cangjie/Basic/Print.h"
#include "NodeWriter.h"
#include "cangjie/AST/Symbol.h"

using namespace Cangjie;
using namespace AST;
using namespace AstWriter;

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeWildcardExpr(AstExpr expr)
{
    auto wildcardExpr = RawStaticCast<const WildcardExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(wildcardExpr);
    auto fbWildcardExpr = SyntaxFormat::CreateWildcardExpr(builder, fbNodeBase);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_WILDCARD_EXPR, fbWildcardExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeBinaryExpr(AstExpr expr)
{
    auto binaryExpr = RawStaticCast<const BinaryExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(binaryExpr);
    auto leftExpr = SerializeExpr(binaryExpr->leftExpr.get());
    auto rightExpr = SerializeExpr(binaryExpr->rightExpr.get());
    auto operatorPos = FlatPosCreateHelper(binaryExpr->operatorPos);
    auto fbBinaryExpr = SyntaxFormat::CreateBinaryExpr(
        builder, fbNodeBase, leftExpr, rightExpr, static_cast<uint16_t>(binaryExpr->op), &operatorPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_BINARY_EXPR, fbBinaryExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeIsExpr(AstExpr expr)
{
    auto isExpr = RawStaticCast<const IsExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(isExpr);
    auto leftExpr = SerializeExpr(isExpr->leftExpr.get());
    auto isType = SerializeType(isExpr->isType.get());
    auto isPos = FlatPosCreateHelper(isExpr->isPos);
    auto fbIsExpr = SyntaxFormat::CreateIsExpr(builder, fbNodeBase, leftExpr, isType, &isPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_IS_EXPR, fbIsExpr.Union());
}
flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeAsExpr(AstExpr expr)
{
    auto asExpr = RawStaticCast<const AsExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(asExpr);
    auto leftExpr = SerializeExpr(asExpr->leftExpr.get());
    auto asType = SerializeType(asExpr->asType.get());
    auto asPos = FlatPosCreateHelper(asExpr->asPos);
    auto fbAsExpr = SyntaxFormat::CreateAsExpr(builder, fbNodeBase, leftExpr, asType, &asPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_AS_EXPR, fbAsExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeLitConstExpr(AstExpr expr)
{
    auto litConstExpr = RawStaticCast<const LitConstExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(litConstExpr);
    auto value = builder.CreateString(litConstExpr->rawString);
    auto fbSiExprs = 
        FlatVectorCreateHelper<SyntaxFormat::Expr, Expr, AstExpr>(std::vector<OwnedPtr<Expr>>(), &NodeWriter::SerializeExpr);
    if (litConstExpr->siExpr != nullptr) {
        fbSiExprs = FlatVectorCreateHelper<SyntaxFormat::Expr, Expr, AstExpr>(litConstExpr->siExpr.get()->strPartExprs, &NodeWriter::SerializeExpr);
    }
    auto fbLitConstExpr = SyntaxFormat::CreateLitConstExpr(builder, fbNodeBase, value,
        static_cast<uint16_t>(litConstExpr->kind), static_cast<uint16_t>(litConstExpr->delimiterNum),
        static_cast<uint16_t>(litConstExpr->stringKind), static_cast<uint16_t>(litConstExpr->isSingleQuote), fbSiExprs);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_LIT_CONST_EXPR, fbLitConstExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeInterpolationExpr(AstExpr expr)
{
    auto interpolationExpr = RawStaticCast<const InterpolationExpr*>(expr);
    if (interpolationExpr == nullptr) {
        auto fbInterpolationExpr = flatbuffers::Offset<SyntaxFormat::InterpolationExpr>();
        return SyntaxFormat::CreateExpr(
            builder, emptyNodeBase, SyntaxFormat::AnyExpr_INTERPOLATION_EXPR, fbInterpolationExpr.Union());
    }
    auto fbNodeBase = SerializeNodeBase(interpolationExpr);
    auto dollarPos = FlatPosCreateHelper(interpolationExpr->dollarPos);
    auto block = SerializeBlock(interpolationExpr->block.get());
    auto fbInterpolationExpr = SyntaxFormat::CreateInterpolationExpr(builder, fbNodeBase, &dollarPos, block);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_INTERPOLATION_EXPR, fbInterpolationExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeUnaryExpr(AstExpr expr)
{
    auto unaryExpr = RawStaticCast<const UnaryExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(unaryExpr);
    auto onlyExpr = SerializeExpr(unaryExpr->expr.get());
    uint16_t op = static_cast<uint16_t>(unaryExpr->op);
    auto operatorPos = FlatPosCreateHelper(unaryExpr->operatorPos);
    auto fbUnaryExpr = SyntaxFormat::CreateUnaryExpr(builder, fbNodeBase, onlyExpr, op, &operatorPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_UNARY_EXPR, fbUnaryExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeParenExpr(AstExpr expr)
{
    auto parenExpr = RawStaticCast<const ParenExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(parenExpr);
    auto onlyExpr = SerializeExpr(parenExpr->expr.get());
    auto leftParenPos = FlatPosCreateHelper(parenExpr->leftParenPos);
    auto rightParenPos = FlatPosCreateHelper(parenExpr->rightParenPos);
    auto fbParenExpr = SyntaxFormat::CreateParenExpr(builder, fbNodeBase, &leftParenPos, onlyExpr, &rightParenPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_PAREN_EXPR, fbParenExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::FuncArg> NodeWriter::SerializeFuncArg(AstFuncArg funcArg)
{
    if (funcArg == nullptr) {
        return flatbuffers::Offset<SyntaxFormat::FuncArg>();
    }
    auto base = SerializeNodeBase(funcArg);
    auto name = builder.CreateString(funcArg->name.GetRawText());
    auto namePos = FlatPosCreateHelper(funcArg->name.GetRawPos());
    auto colonPos = FlatPosCreateHelper(funcArg->colonPos);
    auto fbExpr = SerializeExpr(funcArg->expr.get());
    auto commaPos = FlatPosCreateHelper(funcArg->commaPos);
    auto inout_pos = FlatPosCreateHelper(funcArg->inoutPos);
    return SyntaxFormat::CreateFuncArg(
        builder, base, name, &namePos, &colonPos,fbExpr, &commaPos, funcArg->withInout, &inout_pos);
}

flatbuffers::Offset<SyntaxFormat::CallExpr> NodeWriter::SerializeCallExpr(const CallExpr* callExpr)
{
    if (callExpr == nullptr) {
        return flatbuffers::Offset<SyntaxFormat::CallExpr>();
    }
    auto fbNodeBase = SerializeNodeBase(callExpr);
    auto baseFunc = callExpr->baseFunc.get();
    auto fbBaseFunc = SerializeExpr(baseFunc);
    auto leftParenPos = FlatPosCreateHelper(callExpr->leftParenPos);
    auto rightParenPos = FlatPosCreateHelper(callExpr->rightParenPos);
    auto fbArgs =
        FlatVectorCreateHelper<SyntaxFormat::FuncArg, FuncArg, AstFuncArg>(callExpr->args, &NodeWriter::SerializeFuncArg);
    return SyntaxFormat::CreateCallExpr(builder, fbNodeBase, fbBaseFunc, &leftParenPos, fbArgs, &rightParenPos);
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeCallExpr(const Expr* expr)
{
    auto callExpr = RawStaticCast<const CallExpr*>(expr);
    auto fbCallExpr = SerializeCallExpr(callExpr);
    return SyntaxFormat::CreateExpr(
        builder, SerializeNodeBase(callExpr), SyntaxFormat::AnyExpr_CALL_EXPR, fbCallExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::RefExpr> NodeWriter::SerializeRefExpr(const RefExpr* refExpr)
{
    if (refExpr == nullptr) {
        return flatbuffers::Offset<SyntaxFormat::RefExpr>();
    }
    auto fbNodeBase = SerializeNodeBase(refExpr);
    auto ref = refExpr->ref;
    auto identifier = builder.CreateString(ref.identifier.GetRawText());
    auto identifierPos = FlatPosCreateHelper(ref.identifier.GetRawPos());
    auto fbRef = SyntaxFormat::CreateReference(builder, identifier, &identifierPos);
    auto leftAnglePos = FlatPosCreateHelper(refExpr->leftAnglePos);
    auto fbTypeVec =
        FlatVectorCreateHelper<SyntaxFormat::Type, Type, AstType>(refExpr->typeArguments, &NodeWriter::SerializeType);
    auto rightAnglePos = FlatPosCreateHelper(refExpr->rightAnglePos);
    return SyntaxFormat::CreateRefExpr(builder, fbNodeBase, fbRef, &leftAnglePos, fbTypeVec, &rightAnglePos,
        refExpr->isThis, refExpr->isSuper, refExpr->isQuoteDollar);
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeRefExpr(const Expr* expr)
{
    auto refExpr = RawStaticCast<const RefExpr*>(expr);
    auto fbRefExpr = SerializeRefExpr(refExpr);
    return SyntaxFormat::CreateExpr(builder, SerializeNodeBase(refExpr), SyntaxFormat::AnyExpr_REF_EXPR, fbRefExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeBlockExpr(AstExpr expr)
{
    auto block = RawStaticCast<const Block*>(expr);
    auto fbBlock = SerializeBlock(block);
    return SyntaxFormat::CreateExpr(builder, SerializeNodeBase(block), SyntaxFormat::AnyExpr_BLOCK, fbBlock.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeReturnExpr(AstExpr expr)
{
    auto returnExpr = RawStaticCast<const ReturnExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(returnExpr);
    auto returnPos = FlatPosCreateHelper(returnExpr->returnPos);
    auto fbExpr = SerializeExpr(returnExpr->expr.get());
    if (returnExpr->expr->TestAttr(Attribute::COMPILER_ADD)) {
        fbExpr = flatbuffers::Offset<SyntaxFormat::Expr>();
    }
    auto fbReturnExpr = SyntaxFormat::CreateReturnExpr(builder, fbNodeBase, &returnPos, fbExpr);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_RETURN_EXPR, fbReturnExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeDoWhileExpr(AstExpr expr)
{
    auto doWhileExpr = RawStaticCast<const DoWhileExpr*>(expr);
    auto base = SerializeNodeBase(doWhileExpr);
    auto doPos = FlatPosCreateHelper(doWhileExpr->doPos);
    auto body = SerializeBlock(doWhileExpr->body.get());
    auto whilePos = FlatPosCreateHelper(doWhileExpr->whilePos);
    auto leftParenPos = FlatPosCreateHelper(doWhileExpr->leftParenPos);
    auto condExpr = SerializeExpr(doWhileExpr->condExpr.get());
    auto rightParenPos = FlatPosCreateHelper(doWhileExpr->rightParenPos);
    auto fbDoWhileExpr =
        SyntaxFormat::CreateDoWhileExpr(builder, base, &doPos, body, &whilePos, &leftParenPos, condExpr, &rightParenPos);
    return SyntaxFormat::CreateExpr(builder, base, SyntaxFormat::AnyExpr_DO_WHILE_EXPR, fbDoWhileExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeAssignExpr(AstExpr expr)
{
    auto assignExpr = RawStaticCast<const AssignExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(assignExpr);
    auto fbLeftValue = SerializeExpr(assignExpr->leftValue.get());
    auto assignOp = static_cast<uint16_t>(assignExpr->op);
    auto assignPos = FlatPosCreateHelper(assignExpr->assignPos);
    auto fbRightExpr = SerializeExpr(assignExpr->rightExpr.get());
    auto fbAssignExpr =
        SyntaxFormat::CreateAssignExpr(builder, fbNodeBase, fbLeftValue, assignOp, &assignPos, fbRightExpr);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_ASSIGN_EXPR, fbAssignExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeMemberAccess(AstExpr expr)
{
    auto memberAccess = RawStaticCast<const MemberAccess*>(expr);
    auto fbNodeBase = SerializeNodeBase(memberAccess);
    auto fbBaseExpr = SerializeExpr(memberAccess->baseExpr.get());
    auto dotPos = FlatPosCreateHelper(memberAccess->dotPos);
    auto field = builder.CreateString(memberAccess->field.GetRawText());
    auto fieldPos = FlatPosCreateHelper(memberAccess->field.GetRawPos());
    auto fbTypeArguments = FlatVectorCreateHelper<SyntaxFormat::Type, Type, AstType>(
        memberAccess->typeArguments, &NodeWriter::SerializeType);
    auto leftAnglePos = FlatPosCreateHelper(memberAccess->leftAnglePos);
    auto rightAnglePos = FlatPosCreateHelper(memberAccess->rightAnglePos);
    auto fbMemberAccess = SyntaxFormat::CreateMemberAccess(
        builder, fbNodeBase, fbBaseExpr, &dotPos, field, &fieldPos, &leftAnglePos, fbTypeArguments, &rightAnglePos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_MEMBER_ACCESS, fbMemberAccess.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeLetPatternDestructor(AstExpr expr)
{
    auto letExpr = RawStaticCast<const LetPatternDestructor*>(expr);
    auto fbNodeBase = SerializeNodeBase(letExpr);
    auto fbPatterns = FlatVectorCreateHelper<SyntaxFormat::Pattern, Pattern, AstPattern>(
        letExpr->patterns, &NodeWriter::SerializePattern);
    auto backarrowPos = FlatPosCreateHelper(letExpr->backarrowPos);
    auto initializer = SerializeExpr(letExpr->initializer.get());
    auto bitOrPosVector = CreatePositionVector(letExpr->orPos);
    auto fbLetExpr = SyntaxFormat::CreateLetPatternDestructor(builder, fbNodeBase, fbPatterns, bitOrPosVector,
        &backarrowPos, initializer);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_LET_PATTERN_DESTRUCTOR, fbLetExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeIfExpr(AstExpr expr)
{
    auto ifExpr = RawStaticCast<const IfExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(ifExpr);
    auto ifPos = FlatPosCreateHelper(ifExpr->ifPos);
    auto leftParenPos = FlatPosCreateHelper(ifExpr->leftParenPos);
    auto fbCondExpr = SerializeExpr(ifExpr->condExpr.get());
    auto rightParenPos = FlatPosCreateHelper(ifExpr->rightParenPos);
    auto fbBody = SerializeBlock(ifExpr->thenBody.get());
    auto elsePos = FlatPosCreateHelper(ifExpr->elsePos);
    flatbuffers::Offset<SyntaxFormat::Expr> fbElseBody;
    if (!ifExpr->hasElse) {
        auto fbIfExpr = SyntaxFormat::CreateIfExpr(builder, fbNodeBase, &ifPos, fbCondExpr, fbBody, ifExpr->hasElse,
            &elsePos, fbElseBody, ifExpr->isElseIf, &leftParenPos, &rightParenPos);
        return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_IF_EXPR, fbIfExpr.Union());
    }

    auto fbExpr = SerializeExpr(ifExpr->elseBody.get());
    auto fbIfExpr = SyntaxFormat::CreateIfExpr(builder, fbNodeBase, &ifPos, fbCondExpr, fbBody, ifExpr->hasElse,
        &elsePos, fbExpr, ifExpr->isElseIf, &leftParenPos, &rightParenPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_IF_EXPR, fbIfExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeMatchExpr(AstExpr expr)
{
    auto matchExpr = RawStaticCast<const MatchExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(matchExpr);
    auto leftParenPos = FlatPosCreateHelper(matchExpr->leftParenPos);
    auto fbSelector = SerializeExpr(matchExpr->selector.get());
    auto rightParenPos = FlatPosCreateHelper(matchExpr->rightParenPos);
    auto leftCurlPos = FlatPosCreateHelper(matchExpr->leftCurlPos);
    auto fbMatchcases = FlatVectorCreateHelper<SyntaxFormat::MatchCase, MatchCase, AstMatchCase>(
        matchExpr->matchCases, &NodeWriter::SerializeMatchCase);
    auto fbMatchcaseother = FlatVectorCreateHelper<SyntaxFormat::MatchCaseOther, MatchCaseOther, AstMatchCaseOther>(
        matchExpr->matchCaseOthers, &NodeWriter::SerializeMatchCaseOther);
    auto rightCurlPos = FlatPosCreateHelper(matchExpr->rightCurlPos);
    auto fbMatchExpr = SyntaxFormat::CreateMatchExpr(builder, fbNodeBase, matchExpr->matchMode, &leftParenPos, fbSelector,
        &rightParenPos, &leftCurlPos, fbMatchcases, fbMatchcaseother, &rightCurlPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_MATCH_EXPR, fbMatchExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeWhileExpr(AstExpr expr)
{
    auto whileExpr = RawStaticCast<const WhileExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(whileExpr);
    auto whilePos = FlatPosCreateHelper(whileExpr->whilePos);
    auto leftParenPos = FlatPosCreateHelper(whileExpr->leftParenPos);
    auto fbCondExpr = SerializeExpr(whileExpr->condExpr.get());
    auto rightParenPos = FlatPosCreateHelper(whileExpr->rightParenPos);
    auto fbBody = SerializeBlock(whileExpr->body.get());
    auto fbWhileExpr =
        SyntaxFormat::CreateWhileExpr(builder, fbNodeBase, &whilePos, &leftParenPos, fbCondExpr, &rightParenPos, fbBody);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_WHILE_EXPR, fbWhileExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeArrayLit(AstExpr expr)
{
    auto arrayLit = RawStaticCast<const ArrayLit*>(expr);
    auto fbNodeBase = SerializeNodeBase(arrayLit);
    auto leftCurlPos = FlatPosCreateHelper(arrayLit->leftSquarePos);
    auto fbExs =
        FlatVectorCreateHelper<SyntaxFormat::Expr, Expr, AstExpr>(arrayLit->children, &NodeWriter::SerializeExpr);
    auto commaPosVector = CreatePositionVector(arrayLit->commaPosVector);
    auto rightCurlPos = FlatPosCreateHelper(arrayLit->rightSquarePos);
    auto fbArrayLit =
        SyntaxFormat::CreateArrayLit(builder, fbNodeBase, &leftCurlPos, fbExs, commaPosVector, &rightCurlPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_ARRAY_LIT, fbArrayLit.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeTupleLit(AstExpr expr)
{
    auto tupleLit = RawStaticCast<const TupleLit*>(expr);
    auto fbNodeBase = SerializeNodeBase(tupleLit);
    auto leftParenPos = FlatPosCreateHelper(tupleLit->leftParenPos);
    auto fbExs =
        FlatVectorCreateHelper<SyntaxFormat::Expr, Expr, AstExpr>(tupleLit->children, &NodeWriter::SerializeExpr);
    auto commaPositions = CreatePositionVector(tupleLit->commaPosVector);
    auto rightParenPos = FlatPosCreateHelper(tupleLit->rightParenPos);
    auto fbTupleLit =
        SyntaxFormat::CreateTupleLit(builder, fbNodeBase, &leftParenPos, fbExs, commaPositions, &rightParenPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_TUPLE_LIT, fbTupleLit.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeSubscriptExpr(AstExpr expr)
{
    auto subscriptExpr = RawStaticCast<const SubscriptExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(subscriptExpr);
    auto fbBaseExpr = SerializeExpr(subscriptExpr->baseExpr.get());
    auto leftSquarePos = FlatPosCreateHelper(subscriptExpr->leftParenPos);
    auto fbIndexExprs =
        FlatVectorCreateHelper<SyntaxFormat::Expr, Expr, AstExpr>(subscriptExpr->indexExprs, &NodeWriter::SerializeExpr);
    auto rightSquarePos = FlatPosCreateHelper(subscriptExpr->rightParenPos);
    bool isTupleAccess = subscriptExpr->isTupleAccess;
    auto commaPositions = CreatePositionVector(subscriptExpr->commaPos);
    auto fbSubscriptExpr = SyntaxFormat::CreateSubscriptExpr(
        builder, fbNodeBase, fbBaseExpr, &leftSquarePos, fbIndexExprs, &rightSquarePos, isTupleAccess, commaPositions);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_SUBSCRIPT_EXPR, fbSubscriptExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeRangeExpr(AstExpr expr)
{
    auto rangeExpr = RawStaticCast<const RangeExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(rangeExpr);
    auto fbStartExpr = SerializeExpr(rangeExpr->startExpr.get());
    auto rangePos = FlatPosCreateHelper(rangeExpr->rangePos);
    auto fbStopExpr = SerializeExpr(rangeExpr->stopExpr.get());
    auto colonPos = FlatPosCreateHelper(rangeExpr->colonPos);
    auto fbStepExpr = SerializeExpr(rangeExpr->stepExpr.get());
    bool isClosed = rangeExpr->isClosed;
    auto fbRangeExpr = SyntaxFormat::CreateRangeExpr(
        builder, fbNodeBase, fbStartExpr, &rangePos, fbStopExpr, &colonPos, fbStepExpr, isClosed);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_RANGE_EXPR, fbRangeExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::LambdaExpr> NodeWriter::SerializeLambdaExpr(const LambdaExpr* lambdaExpr)
{
    if (lambdaExpr == nullptr) {
        return flatbuffers::Offset<SyntaxFormat::LambdaExpr>();
    }
    auto fbNodeBase = SerializeNodeBase(lambdaExpr);
    auto fbBody = SerializeFuncBody(lambdaExpr->funcBody.get());
    auto mockSupported = lambdaExpr->TestAttr(Attribute::MOCK_SUPPORTED);
    return SyntaxFormat::CreateLambdaExpr(builder, fbNodeBase, fbBody, mockSupported);
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeLambdaExpr(const Expr* expr)
{
    auto lambdaExpr = RawStaticCast<const LambdaExpr*>(expr);
    auto fbLambdaExpr = SerializeLambdaExpr(lambdaExpr);
    return SyntaxFormat::CreateExpr(
        builder, SerializeNodeBase(lambdaExpr), SyntaxFormat::AnyExpr_LAMBDA_EXPR, fbLambdaExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeSpawnExpr(AstExpr expr)
{
    auto spawnExpr = RawStaticCast<const SpawnExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(spawnExpr);
    auto spawnPos = FlatPosCreateHelper(spawnExpr->spawnPos);
    auto taskExpr = SerializeExpr(spawnExpr->task.get());
    auto hasArg = (spawnExpr->arg.get() != nullptr);
    auto spawnArgExpr = SerializeExpr(spawnExpr->arg.get());
    auto leftParenPos = FlatPosCreateHelper(spawnExpr->leftParenPos);
    auto rightParenPos = FlatPosCreateHelper(spawnExpr->rightParenPos);
    auto fbSpawnExpr = SyntaxFormat::CreateSpawnExpr(
        builder, fbNodeBase, &spawnPos, taskExpr, hasArg, spawnArgExpr, &leftParenPos, &rightParenPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_SPAWN_EXPR, fbSpawnExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeSynchronizedExpr(AstExpr expr)
{
    auto synchronizedExpr = RawStaticCast<const SynchronizedExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(synchronizedExpr);
    auto syncPos = FlatPosCreateHelper(synchronizedExpr->syncPos);
    auto leftParenPos = FlatPosCreateHelper(synchronizedExpr->leftParenPos);
    auto mutexExpr = SerializeExpr(synchronizedExpr->mutex.get());
    auto rightParenPos = FlatPosCreateHelper(synchronizedExpr->rightParenPos);
    auto body = SerializeBlock(synchronizedExpr->body.get());
    auto fbSynchronizedExpr = SyntaxFormat::CreateSynchronizedExpr(
        builder, fbNodeBase, &syncPos, &leftParenPos, mutexExpr, &rightParenPos, body);
    return SyntaxFormat::CreateExpr(
        builder, fbNodeBase, SyntaxFormat::AnyExpr_SYNCHRONIZED_EXPR, fbSynchronizedExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeTrailingClosureExpr(AstExpr expr)
{
    auto type = SyntaxFormat::AnyExpr_TRAILING_CLOSURE_EXPR;
    auto trailingClosureExpr = RawStaticCast<const TrailingClosureExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(trailingClosureExpr);
    auto leftLambdaPos = FlatPosCreateHelper(trailingClosureExpr->leftLambda);
    auto fbExpr = SerializeExpr(trailingClosureExpr->expr.get());
    auto fbLambdaExpr = SerializeLambdaExpr(trailingClosureExpr->lambda.get());
    auto rightLambdaPos = FlatPosCreateHelper(trailingClosureExpr->rightLambda);
    auto fbTrailingClosureExpr = SyntaxFormat::CreateTrailingClosureExpr(
        builder, fbNodeBase, &leftLambdaPos, fbExpr, fbLambdaExpr, &rightLambdaPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, type, fbTrailingClosureExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeTypeConvExpr(AstExpr expr)
{
    auto type = SyntaxFormat::AnyExpr_TYPE_CONV_EXPR;
    auto typeConvExpr = RawStaticCast<const TypeConvExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(typeConvExpr);
    auto fbPrimitiveType = SerializeType(typeConvExpr->type.get());
    auto leftParenPos = FlatPosCreateHelper(typeConvExpr->leftParenPos);
    auto fbExpr = SerializeExpr(typeConvExpr->expr.get());
    auto rightParenPos = FlatPosCreateHelper(typeConvExpr->rightParenPos);
    auto fbTypeConvExpr =
        SyntaxFormat::CreateTypeConvExpr(builder, fbNodeBase, fbPrimitiveType, &leftParenPos, fbExpr, &rightParenPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, type, fbTypeConvExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeTryExpr(AstExpr expr)
{
    auto tryExpr = RawStaticCast<const TryExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(tryExpr);
    auto fbLParenPos = FlatPosCreateHelper(tryExpr->lParen);
    auto fbResource = FlatVectorCreateHelper<SyntaxFormat::VarDecl, VarDecl, const VarDecl*>(
        tryExpr->resourceSpec, &NodeWriter::SerializeVarDecl);
    auto fbRParenPos = FlatPosCreateHelper(tryExpr->rParen);
    auto fbCommaPos = CreatePositionVector(tryExpr->resourceSpecCommaPos);
    auto fbTryBlock = SerializeBlock(tryExpr->tryBlock.get());
    auto fbCatchPos = CreatePositionVector(tryExpr->catchPosVector);
    auto fbCatchLParenPos = CreatePositionVector(tryExpr->catchLParenPosVector);
    auto fbCatchRParenPos = CreatePositionVector(tryExpr->catchRParenPosVector);
    auto fbCatchBlocks =
        FlatVectorCreateHelper<SyntaxFormat::Block, Block, AstBlock>(tryExpr->catchBlocks, &NodeWriter::SerializeBlock);
    auto fbCatchPatterns = FlatVectorCreateHelper<SyntaxFormat::Pattern, Pattern, AstPattern>(
        tryExpr->catchPatterns, &NodeWriter::SerializePattern);
    std::vector<flatbuffers::Offset<SyntaxFormat::Handler>> vecHandlers;
    for (auto& handler : tryExpr->handlers) {
        auto fbPos = FlatPosCreateHelper(handler.pos);
        auto fbCommandPattern = SerializePattern(handler.commandPattern.get());
        auto fbHandleBlock = SerializeBlock(handler.block.get());
        auto fbHanlder =
            SyntaxFormat::CreateHandler(builder, &fbPos, fbCommandPattern, fbHandleBlock);
        vecHandlers.push_back(fbHanlder);
    }
    auto fbHandlers = builder.CreateVector(vecHandlers);
    auto finallyPos = FlatPosCreateHelper(tryExpr->finallyPos);
    auto fbFinallyBlock = SerializeBlock(tryExpr->finallyBlock.get());
    auto fbTryExpr =
        SyntaxFormat::CreateTryExpr(builder, fbNodeBase, fbResource, tryExpr->isDesugaredFromTryWithResources,
            fbTryBlock, fbCatchBlocks, fbCatchPatterns, &finallyPos, fbFinallyBlock,
            &fbLParenPos, &fbRParenPos, fbCommaPos, fbCatchPos, fbCatchLParenPos, fbCatchRParenPos, fbHandlers);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_TRY_EXPR, fbTryExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeThrowExpr(AstExpr expr)
{
    auto throwExpr = RawStaticCast<const ThrowExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(throwExpr);
    auto fbExpr = SerializeExpr(throwExpr->expr.get());
    auto fbThrowExpr = SyntaxFormat::CreateThrowExpr(builder, fbNodeBase, fbExpr);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_THROW_EXPR, fbThrowExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializePerformExpr(AstExpr expr)
{
    auto performExpr = RawStaticCast<const PerformExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(performExpr);
    auto fbExpr = SerializeExpr(performExpr->expr.get());
    auto fbPerformExpr = SyntaxFormat::CreatePerformExpr(builder, fbNodeBase, fbExpr);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_PERFORM_EXPR, fbPerformExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeResumeExpr(AstExpr expr)
{
    auto resumeExpr = RawStaticCast<const ResumeExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(resumeExpr);
    auto withPos = FlatPosCreateHelper(resumeExpr->withPos);
    auto withExpr = SerializeExpr(resumeExpr->withExpr);
    auto throwingPos = FlatPosCreateHelper(resumeExpr->throwingPos);
    auto throwingExpr = SerializeExpr(resumeExpr->throwingExpr);
    auto fbResumeExpr =
        SyntaxFormat::CreateResumeExpr(builder, fbNodeBase, &withPos, withExpr, &throwingPos, throwingExpr);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_RESUME_EXPR, fbResumeExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializePrimitiveTypeExpr(AstExpr expr)
{
    auto primitiveTypeExpr = RawStaticCast<const PrimitiveTypeExpr*>(expr);
    auto fbTypeBase = SerializeNodeBase(primitiveTypeExpr);
    auto typeKind = static_cast<uint16_t>(primitiveTypeExpr->typeKind);
    auto fbPrimTypeExpr = SyntaxFormat::CreatePrimitiveTypeExpr(builder, fbTypeBase, typeKind);
    return SyntaxFormat::CreateExpr(builder, fbTypeBase, SyntaxFormat::AnyExpr_PRIMITIVE_TYPE_EXPR, fbPrimTypeExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeForInExpr(AstExpr expr)
{
    auto forinExpr = RawStaticCast<const ForInExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(forinExpr);
    auto leftParenPos = FlatPosCreateHelper(forinExpr->leftParenPos);
    auto fbPattern = SerializePattern(forinExpr->pattern.get());
    auto inPos = FlatPosCreateHelper(forinExpr->inPos);
    auto fbInExpr = SerializeExpr(forinExpr->inExpression.get());
    auto rightParenPos = FlatPosCreateHelper(forinExpr->rightParenPos);
    auto ifPos = FlatPosCreateHelper(forinExpr->wherePos);
    auto fbPatternGuard = SerializeExpr(forinExpr->patternGuard.get());
    auto fbBody = SerializeBlock(forinExpr->body.get());
    auto fbForInExpr = SyntaxFormat::CreateForInExpr(builder, fbNodeBase, &leftParenPos, fbPattern, &inPos, fbInExpr,
        &rightParenPos, &ifPos, fbPatternGuard, fbBody);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_FOR_IN_EXPR, fbForInExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::NodeBase> NodeWriter::SerializeNodeBase(AstNode node, SourceManager* sm)
{
    if (node == nullptr) {
        return flatbuffers::Offset<SyntaxFormat::NodeBase>();
    }
    // NodeBase is the attrs every Node inherits from
    auto beginPos = FlatPosCreateHelper(node->begin);
    auto endPos = FlatPosCreateHelper(node->end);
    auto str = Cangjie::AST::ASTKIND_TO_STRING_MAP[node->astKind];
    auto astKind = builder.CreateString(str);
    std::string path = "";
    if (sm != nullptr) {
        path = sm->GetSource(node->begin.fileID).path;
    }
    auto filePath = builder.CreateString(path);
    auto comments = SerializeCommentGroups(node->comments);
    return SyntaxFormat::CreateNodeBase(builder, &beginPos, &endPos, astKind, filePath, comments);
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeJumpExpr(AstExpr expr)
{
    auto jumpExpr = RawStaticCast<const JumpExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(jumpExpr);
    auto isBreak = jumpExpr->isBreak;
    auto fbJumpExpr = SyntaxFormat::CreateJumpExpr(builder, fbNodeBase, isBreak);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_JUMP_EXPR, fbJumpExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeIncOrDecExpr(AstExpr expr)
{
    auto incOrDecExpr = RawStaticCast<const IncOrDecExpr*>(expr);
    auto base = SerializeNodeBase(incOrDecExpr);
    uint16_t op = static_cast<uint16_t>(incOrDecExpr->op);
    auto operatorPos = FlatPosCreateHelper(incOrDecExpr->operatorPos);
    auto expr0 = SerializeExpr(incOrDecExpr->expr.get());
    auto fbIncOrDecExpr = SyntaxFormat::CreateIncOrDecExpr(builder, base, op, &operatorPos, expr0);
    return SyntaxFormat::CreateExpr(builder, base, SyntaxFormat::AnyExpr_INC_OR_DEC_EXPR, fbIncOrDecExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeOptionalExpr(AstExpr expr)
{
    auto optionalExpr = RawStaticCast<const OptionalExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(optionalExpr);
    auto baseExpr = SerializeExpr(optionalExpr->baseExpr.get());
    auto questPos = FlatPosCreateHelper(optionalExpr->questPos);
    auto fbOptionalExpr = SyntaxFormat::CreateOptionalExpr(builder, fbNodeBase, baseExpr, &questPos);
    return SyntaxFormat::CreateExpr(builder, fbNodeBase, SyntaxFormat::AnyExpr_OPTIONAL_EXPR, fbOptionalExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeOptionalChainExpr(AstExpr expr)
{
    auto optionalChainExpr = RawStaticCast<const OptionalChainExpr*>(expr);
    auto fbNodeBase = SerializeNodeBase(optionalChainExpr);
    auto optexpr = SerializeExpr(optionalChainExpr->expr.get());
    auto fbOptionalChainExpr = SyntaxFormat::CreateOptionalChainExpr(builder, fbNodeBase, optexpr);
    return SyntaxFormat::CreateExpr(
        builder, fbNodeBase, SyntaxFormat::AnyExpr_OPTIONAL_CHAIN_EXPR, fbOptionalChainExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeTokenPart(AstExpr expr)
{
    auto tokenPart = RawStaticCast<const TokenPart*>(expr);
    auto vecToken = TokensVectorCreateHelper(tokenPart->tokens);
    auto fbTokens = builder.CreateVector(vecToken);
    auto fbTokenPart = SyntaxFormat::CreateTokenPart(builder, fbTokens);
    return SyntaxFormat::CreateExpr(
        builder, SerializeNodeBase(tokenPart), SyntaxFormat::AnyExpr_TOKEN_PART, fbTokenPart.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeQuoteExpr(AstExpr expr)
{
    auto quoteExpr = RawStaticCast<const QuoteExpr*>(expr);
    auto base = SerializeNodeBase(quoteExpr);
    auto leftParenPos = FlatPosCreateHelper(quoteExpr->leftParenPos);
    auto rightParenPos = FlatPosCreateHelper(quoteExpr->rightParenPos);
    std::vector<flatbuffers::Offset<SyntaxFormat::Expr>> vecExpr;
    for (auto& child : quoteExpr->exprs) {
        vecExpr.push_back(SerializeExpr(child.get()));
    }
    auto fbExprs = builder.CreateVector(vecExpr);
    auto fbQuoteExpr = SyntaxFormat::CreateQuoteExpr(builder, base, &leftParenPos, fbExprs, &rightParenPos);
    return SyntaxFormat::CreateExpr(builder, base, SyntaxFormat::AnyExpr_QUOTE_EXPR, fbQuoteExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeMacroExpandExpr(AstExpr expr)
{
    auto macroExpandExpr = RawStaticCast<const MacroExpandExpr*>(expr);
    auto base = SerializeNodeBase(macroExpandExpr);
    auto invocation = MacroInvocationCreateHelper(macroExpandExpr->invocation);
    auto identifier = builder.CreateString(macroExpandExpr->identifier.Val());
    auto identifierPos = FlatPosCreateHelper(macroExpandExpr->identifier.Begin());
    auto annotationVec = FlatVectorCreateHelper<SyntaxFormat::Annotation, Annotation, AstAnnotation>(
        macroExpandExpr->annotations, &NodeWriter::SerializeAnnotation);
    std::vector<flatbuffers::Offset<SyntaxFormat::Modifier>> vecModifier;
    auto modifiersVec = SortModifierByPos(macroExpandExpr->modifiers);
    for (auto& mod : modifiersVec) {
        auto fbMod = SerializeModifier(mod);
        vecModifier.push_back(fbMod);
    }
    auto fbModVec = builder.CreateVector(vecModifier);
    auto fbMacroExpandExpr = SyntaxFormat::CreateMacroExpandExpr(
        builder, base, invocation, identifier, &identifierPos, annotationVec, fbModVec);
    return SyntaxFormat::CreateExpr(builder, base, SyntaxFormat::AnyExpr_MACRO_EXPAND_EXPR, fbMacroExpandExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeArrayExpr(AstExpr expr)
{
    auto arrayExpr = RawStaticCast<const ArrayExpr*>(expr);
    auto base = SerializeNodeBase(arrayExpr);
    auto type = SerializeType(arrayExpr->type.get());
    auto leftParenPos = FlatPosCreateHelper(arrayExpr->leftParenPos);
    auto args = FlatVectorCreateHelper<SyntaxFormat::FuncArg, FuncArg, AstFuncArg>(
        arrayExpr->args, &NodeWriter::SerializeFuncArg);
    auto rightParenPos = FlatPosCreateHelper(arrayExpr->rightParenPos);
    auto isValueArray = arrayExpr->isValueArray;
    auto fbArrayExpr =
        SyntaxFormat::CreateArrayExpr(builder, base, type, &leftParenPos, args, &rightParenPos, isValueArray);
    return SyntaxFormat::CreateExpr(builder, base, SyntaxFormat::AnyExpr_ARRAY_EXPR, fbArrayExpr.Union());
}

flatbuffers::Offset<SyntaxFormat::Expr> NodeWriter::SerializeExpr(AstExpr expr)
{
    if (expr == nullptr) {
        return flatbuffers::Offset<SyntaxFormat::Expr>();
    }
    static std::unordered_map<AST::ASTKind, std::function<SyntaxFormatExpr(NodeWriter & nw, AstExpr expr)>>
        serializeExprMap = {
            {ASTKind::WILDCARD_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeWildcardExpr(expr); }},
            {ASTKind::BINARY_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeBinaryExpr(expr); }},
            {ASTKind::LIT_CONST_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeLitConstExpr(expr); }},
            {ASTKind::INTERPOLATION_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeInterpolationExpr(expr); }},
            {ASTKind::UNARY_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeUnaryExpr(expr); }},
            {ASTKind::PAREN_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeParenExpr(expr); }},
            {ASTKind::CALL_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeCallExpr(expr); }},
            {ASTKind::REF_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeRefExpr(expr); }},
            {ASTKind::RETURN_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeReturnExpr(expr); }},
            {ASTKind::ASSIGN_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeAssignExpr(expr); }},
            {ASTKind::MEMBER_ACCESS, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeMemberAccess(expr); }},
            {ASTKind::IF_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeIfExpr(expr); }},
            {ASTKind::BLOCK, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeBlockExpr(expr); }},
            {ASTKind::LAMBDA_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeLambdaExpr(expr); }},
            {ASTKind::TYPE_CONV_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeTypeConvExpr(expr); }},
            {ASTKind::FOR_IN_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeForInExpr(expr); }},
            {ASTKind::ARRAY_LIT, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeArrayLit(expr); }},
            {ASTKind::TUPLE_LIT, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeTupleLit(expr); }},
            {ASTKind::SUBSCRIPT_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeSubscriptExpr(expr); }},
            {ASTKind::RANGE_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeRangeExpr(expr); }},
            {ASTKind::MATCH_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeMatchExpr(expr); }},
            {ASTKind::TRY_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeTryExpr(expr); }},
            {ASTKind::THROW_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeThrowExpr(expr); }},
            {ASTKind::PERFORM_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializePerformExpr(expr); }},
            {ASTKind::RESUME_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeResumeExpr(expr); }},
            {ASTKind::JUMP_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeJumpExpr(expr); }},
            {ASTKind::WHILE_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeWhileExpr(expr); }},
            {ASTKind::DO_WHILE_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeDoWhileExpr(expr); }},
            {ASTKind::INC_OR_DEC_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeIncOrDecExpr(expr); }},
            {ASTKind::TOKEN_PART, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeTokenPart(expr); }},
            {ASTKind::QUOTE_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeQuoteExpr(expr); }},
            {ASTKind::IS_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeIsExpr(expr); }},
            {ASTKind::AS_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeAsExpr(expr); }},
            {ASTKind::SPAWN_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeSpawnExpr(expr); }},
            {ASTKind::SYNCHRONIZED_EXPR,
                [](NodeWriter& nw, AstExpr expr) { return nw.SerializeSynchronizedExpr(expr); }},
            {ASTKind::OPTIONAL_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeOptionalExpr(expr); }},
            {ASTKind::OPTIONAL_CHAIN_EXPR,
                [](NodeWriter& nw, AstExpr expr) { return nw.SerializeOptionalChainExpr(expr); }},
            {ASTKind::TRAIL_CLOSURE_EXPR,
                [](NodeWriter& nw, AstExpr expr) { return nw.SerializeTrailingClosureExpr(expr); }},
            {ASTKind::PRIMITIVE_TYPE_EXPR,
                [](NodeWriter& nw, AstExpr expr) { return nw.SerializePrimitiveTypeExpr(expr); }},
            {ASTKind::LET_PATTERN_DESTRUCTOR,
                [](NodeWriter& nw, AstExpr expr) { return nw.SerializeLetPatternDestructor(expr); }},
            {ASTKind::MACRO_EXPAND_EXPR,
                [](NodeWriter& nw, AstExpr expr) { return nw.SerializeMacroExpandExpr(expr); }},
            {ASTKind::ARRAY_EXPR, [](NodeWriter& nw, AstExpr expr) { return nw.SerializeArrayExpr(expr); }},
        };
    // Match ReplaceExpr func.
    auto serializeFunc = serializeExprMap.find(expr->astKind);
    if (serializeFunc != serializeExprMap.end()) {
        return serializeFunc->second(*this, expr);
    }
    Errorln("Expr Not Supported in Syntax Yet\n");
    return flatbuffers::Offset<SyntaxFormat::Expr>();
}
