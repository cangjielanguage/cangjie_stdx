/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.syntax

public import std.ast.{Tokens, Token, TokenKind}
import std.ast.getTokenKind
import std.collection.{ArrayStack, ArrayList}
import flatbuffers.*

foreign func CJ_ParseFile(path: CString): CPointer<ParseRes>

foreign func CJ_ParseText(text: CString): CPointer<ParseRes>

foreign func CJ_ParseTokens(tokens: CPointer<UInt8>, tokenCounter: CPointer<Int64>, refreshPos: Bool): CPointer<ParseRes>

func findError(diags: Array<Diagnostic>): String {
    var res = ""
    for (diag in diags) {
        match (diag.diagInfo) {
            case Error(err, hint) => res += err + "\n" + hint
            case _ => ()
        }
    }
    return res
}

class ParserImpl {
    ParserImpl(private let filePath: String) {}

    func parseFile(): (?SyntaxNodeImpl, Array<Diagnostic>) {
        let (node, msg) = NodeLoader.load(filePath)
        // build impl tree by SyntaxFormat_Node
        let file: ?SyntaxNodeImpl = if (let Some(root) <- node) {
            FlatbufferNodeTranslator.translate(root)
        } else {
            None
        }
        (file, msg)
    }

    func getPreChildren(text: String): Array<SyntaxNodeImpl> {
        let builder = SyntaxNodeBuilder()
        let preChildren = ArrayList<SyntaxNodeImpl>()
        var cnt = 0
        // normalize NewLine to eliminate platform differences
        let tmpText = text.replace("\r\n", "\n")
        for (i in 0..tmpText.size) {
            let cur = tmpText[i..i + 1]
            // whitespace ended
            if (cur != "\n" && cur != " ") {
                break
            }
            // cnt increase
            if (cnt == 0 || tmpText[i - 1..i] == cur) {
                cnt += 1
            }
            // cnt downto 0, add current whitespace to array
            if (i < tmpText.size - 1 && tmpText[i + 1..i + 2] != cur) {
                if (cur == "\n") {
                    preChildren.add(builder.buildNewline(cnt))
                } else {
                    preChildren.add(builder.buildSpace(cnt))
                }
                cnt = 0
            }
        }
        return preChildren.toArray()
    }

    func parseText(text: String): (?SyntaxNodeImpl, Array<Diagnostic>) {
        let (node, msg) = NodeLoader.loadText(text)
        // build impl tree by SyntaxFormat_Node
        let res: ?SyntaxNodeImpl = if (let Some(root) <- node) {
            let errMsg = findError(msg)
            if (errMsg != "") {
                throw Exception("unsupported node type or parse error in parseText function:\n${errMsg}")
            }
            let preChildren = getPreChildren(text)
            FlatbufferNodeTranslator.translate(root, preChildren: preChildren.toArray())
        } else {
            None
        }
        (res, msg)
    }

    func parseTokens(tokens: Tokens, refreshPos: Bool): (?SyntaxNodeImpl, Array<Diagnostic>) {
        let (node, msg) = NodeLoader.loadTokens(tokens, refreshPos)
        // build impl tree by SyntaxFormat_Node
        let res: ?SyntaxNodeImpl = if (let Some(root) <- node) {
            FlatbufferNodeTranslator.translate(root)
        } else {
            None
        }
        (res, msg)
    }
}

// Extract all non-null elements from an Array<Option<T>>
private func getElements<T>(nodes: Array<Option<T>>): Array<T> {
    let elements = ArrayList<T>()
    for (node in nodes) {
        if (let Some(element) <- node) {
            elements.add(element)
        }
    }
    return elements.toArray()
}

private func transDiag(diag: SyntaxFormat_DiagInfo, fileInfo: FileInfos): Diagnostic {
    let msg = unsafe { String.fromUtf8Unchecked(diag.GetMsg()) }
    let hint = unsafe { String.fromUtf8Unchecked(diag.GetHint()) }
    let info = match (diag.GetSeverity()) {
        case 0 => DiagnosticInfo.Error(msg, hint)
        case 1 => DiagnosticInfo.Warning(msg, hint)
        case _ => throw Exception("unsupported severity kind (only support note or hint)")
    }
    var (begin, end) = (CodePosition(), CodePosition())
    if (let Some(range) <- diag.GetRange()) {
        begin = CodePosition(range.GetBegin().line, range.GetBegin().column, fileInfo)
        end = CodePosition(range.GetEnd().line, range.GetEnd().column, fileInfo)
    }
    return Diagnostic(CodePositionRange(begin, end), info)
}

private func transDiags(diags: SyntaxFormat_Diags, filePath: String): Array<Diagnostic> {
    let ret = ArrayList<Diagnostic>()
    let filePathArray = filePath.split(SEPARATOR)
    let fileName = if (filePathArray.size > 0) {
        filePathArray[filePathArray.size - 1]
    } else {
        ""
    }
    let fileInfo = FileInfos(fileName, filePath)
    for (diag in getElements<SyntaxFormat_DiagInfo>(diags.GetDiags())) {
        ret.add(transDiag(diag, fileInfo))
    }
    return ret.toArray()
}

private class NodeLoader {
    private let text: String
    private let tokens: Tokens
    // read 4 bytes for buffer size
    static const HEADER_SIZE: Int64 = 4
    private NodeLoader(private let filePath: String, private var diagInfo!: Array<Diagnostic> = []) {
        this.text = ""
        this.tokens = Tokens()
    }
    private init(text!: String) {
        this.text = text
        this.tokens = Tokens()
        this.filePath = ""
        this.diagInfo = []
    }

    private init(tokens!: Tokens) {
        this.text = ""
        this.tokens = tokens
        this.filePath = ""
        this.diagInfo = []
    }

    static func load(filePath: String): (?SyntaxFormat_Node, Array<Diagnostic>) {
        let loader = NodeLoader(filePath)
        (unsafe { loader.loadNodeFromFile() }, loader.diagInfo)
    }

    static func loadText(text: String): (?SyntaxFormat_Node, Array<Diagnostic>) {
        let loader = NodeLoader(text: text)
        (unsafe { loader.loadNodeFromText() }, loader.diagInfo)
    }

    static func loadTokens(tokens: Tokens, refreshPos: Bool): (?SyntaxFormat_Node, Array<Diagnostic>) {
        let loader = NodeLoader(tokens: tokens)
        (unsafe { loader.loadNodeFromTokens(refreshPos) }, loader.diagInfo)
    }

    private func getDiags(diagNode: CPointer<UInt8>) {
        let dataSize = Int64(getInt32(Array<UInt8>(HEADER_SIZE, {x: Int64 => unsafe { diagNode.read(x) }})))
        if (dataSize > 0) {
            let flatBuf = Array<UInt8>(dataSize, {x: Int64 => unsafe { diagNode.read(x) }})
            diagInfo = transDiags(SyntaxFormat_Diags(flatBuf[HEADER_SIZE..], 0), filePath)
        }
    }

    private func getNode(pnode: CPointer<UInt8>): ?SyntaxFormat_Node {
        let dataSize = Int64(getInt32(Array<UInt8>(HEADER_SIZE, {x: Int64 => unsafe { pnode.read(x) }})))
        if (dataSize <= 0) {
            return None
        }
        let flatBuf = Array<UInt8>(dataSize, {x: Int64 => unsafe { pnode.read(x) }})
        return SyntaxFormat_Node(flatBuf[HEADER_SIZE..], 0)
    }

    private unsafe func getParseResultPointers(resPtr: CPointer<ParseRes>): (CPointer<UInt8>, CPointer<UInt8>) {
        if (resPtr.isNull()) {
            throw Exception("the parsing result is empty.")
        }
        let res = resPtr.read()
        return (res.node, res.errMsg)
    }

    private unsafe func loadNodeFromFile(): ?SyntaxFormat_Node {
        var pathPtr: CString = CString(CPointer<UInt8>())
        var nodePtr = CPointer<UInt8>()
        var resPtr = CPointer<ParseRes>()
        var diagPtr = CPointer<UInt8>()
        try {
            pathPtr = LibC.mallocCString(filePath)
            if (pathPtr.isNull()) {
                throw Exception("mallocCString failed for file path.")
            }
            resPtr = CJ_ParseFile(pathPtr)
            (nodePtr, diagPtr) = getParseResultPointers(resPtr)
            if (nodePtr.isNull() && diagPtr.isNull()) {
                throw Exception("unsupported node type in parseFile function.")
            }
            if (!diagPtr.isNull()) {
                getDiags(diagPtr)
            }
            if (nodePtr.isNull()) {
                return None
            }
            return getNode(nodePtr)
        } finally {
            // free memory allocated in C.
            LibC.free(pathPtr)
            LibC.free(nodePtr)
            LibC.free(diagPtr)
            LibC.free(resPtr)
        }
    }

    private unsafe func loadNodeFromText(): ?SyntaxFormat_Node {
        var textPtr: CString = CString(CPointer<UInt8>())
        var nodePtr = CPointer<UInt8>()
        var resPtr = CPointer<ParseRes>()
        var diagPtr = CPointer<UInt8>()
        try {
            textPtr = LibC.mallocCString(text)
            if (textPtr.isNull()) {
                throw Exception("mallocCString failed for text.")
            }
            resPtr = CJ_ParseText(textPtr)
            (nodePtr, diagPtr) = getParseResultPointers(resPtr)
            if (nodePtr.isNull() && diagPtr.isNull()) {
                throw Exception("unsupported node type in parseText function.")
            }
            if (!diagPtr.isNull()) {
                getDiags(diagPtr)
            }
            if (nodePtr.isNull()) {
                return None
            }
            return getNode(nodePtr)
        } finally {
            // free memory allocated in C.
            LibC.free(textPtr)
            LibC.free(nodePtr)
            LibC.free(diagPtr)
            LibC.free(resPtr)
        }
    }

    private unsafe func loadNodeFromTokens(refreshPos: Bool): ?SyntaxFormat_Node {
        var tokensPtr = CPointer<UInt8>()
        var nodePtr = CPointer<UInt8>()
        var resPtr = CPointer<ParseRes>()
        var diagPtr = CPointer<UInt8>()
        let sizeOfInt64 = 8
        var tokensCounterPtr: CPointer<Int64> = LibC.malloc<Int64>(count: sizeOfInt64)
        try {
            tokensPtr = unsafePointerCastFromUint8Array(tokens.toBytes())
            if (tokensPtr.isNull()) {
                throw Exception("the input tokens is empty.")
            }
            resPtr = CJ_ParseTokens(tokensPtr, tokensCounterPtr, refreshPos)
            if (resPtr.isNull()) {
                throw Exception("the parsing result is empty.")
                return None
            }
            let res = resPtr.read()
            if (!res.errMsg.isNull()) {
                let diagNode = res.errMsg
                diagPtr = diagNode // backup for free
                getDiags(diagNode)
            }
            if (res.node.isNull()) {
                if (res.errMsg.isNull()) {
                    throw Exception("unsupported node type in parseTokens function.")
                }
                return None
            }
            let errMsg = findError(diagInfo)
            if (errMsg != "") {
                nodePtr = res.node
                throw Exception("unsupported node type or parse error in parseTokens function:\n${errMsg}")
            }
            let tokenCnt: Int64 = tokensCounterPtr.read()
            if (tokenCnt == 1) {
                nodePtr = res.node
                throw Exception("parseTokens function not support parse more than one node.")
            }
            let pnode = res.node
            nodePtr = pnode // backup for free
            return getNode(pnode)
        } finally {
            // free memory allocated in C.
            LibC.free(tokensPtr)
            LibC.free(nodePtr)
            LibC.free(diagPtr)
            LibC.free(resPtr)
            LibC.free(tokensCounterPtr)
        }
    }
}

private class FlatbufferNodeTranslator {
    private let builder = SyntaxNodeBuilder()
    private var cursorLine: Int32 = 1 // default (line: 1, column: 1)
    private var cursorColumn: Int32 = 1
    private var curChildren = ArrayList<SyntaxNodeImpl>() // record current context node
    private var innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
    private var leadCommentNodes = ArrayList<SyntaxNodeImpl>()
    private var trailComments = Array<Option<SyntaxFormat_CommentGroup>>()

    static func translate(root: SyntaxFormat_Node, preChildren!: Array<SyntaxNodeImpl> = []): ?SyntaxNodeImpl {
        FlatbufferNodeTranslator().transRoot(root, preChildren)
    }

    private func transRoot(root: SyntaxFormat_Node, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let table = root.table
        let o: UInt16 = table.offset(root.ROOT)
        let off: UInt32 = UInt32(o) + table.pos
        match (root.GetRootType()) {
            case AnyNode_FILE => transFile(SyntaxFormat_File(table.bytes, off))
            case AnyNode_DECL => transDecl(SyntaxFormat_Decl(table.bytes, off), preChildren)
            case AnyNode_EXPR => transExpr(SyntaxFormat_Expr(table.bytes, off), preChildren)
            case AnyNode_IMPORT_SPEC => transImportList(SyntaxFormat_ImportSpec(table.bytes, off))
            case AnyNode_FEATURES_DIRECTIVE => transFeaturesDirective(SyntaxFormat_FeaturesDirective(table.bytes, off))
            case _ => throw Exception("ParseException: The current version does not support this node.")
        }
    }

    /* util funcs*/
    // add a child into parent
    private func addChild(children: ArrayList<SyntaxNodeImpl>, node: ?SyntaxNodeImpl) {
        if (let Some(child) <- node) {
            children.add(child)
        }
    }

    private func isBetweenCursorAndDest(cursorLine: Int32, cursorColumn: Int32, desLine: Int32, desColumn: Int32,
        commentLine: Int32, commentColumn: Int32): Bool {
        // check if the comments locate between the Cursor and the Destination position
        let afterCursor: Bool = cursorLine < commentLine || (cursorLine == commentLine && cursorColumn <= commentColumn)
        let beforeDest: Bool = commentLine < desLine || (commentLine == desLine && commentColumn < desColumn)
        if (afterCursor && beforeDest) {
            return true
        }
        return false
    }

    private func addInnerComments(line: Int32, column: Int32, needNewLine!: Bool = true): Unit {
        for (commentGroup in innerComments) {
            let tmpGroupList = [commentGroup]
            if (let Some(cmtStartPos) <- getCommentGroupListBeginPos(tmpGroupList) && isBetweenCursorAndDest(cursorLine,
                cursorColumn, line, column, cmtStartPos.line, cmtStartPos.column)) {
                /*
                if comments exist, and the comments locate between the Cursor and the Destination position,
                addWhitespace before the comment, then addComments, addWhitespace before the Destination position at last
                 */
                addWhitespaceWithoutComment(cmtStartPos.line, cmtStartPos.column, needNewLine: needNewLine)
                moveCursorColumn(cmtStartPos, 0)

                let tmpChildren = curChildren
                addChild(curChildren, transCommentGroupList(tmpGroupList))
                curChildren = tmpChildren
            }
        }
    }

    // add whitespace into curNode by [(cursorLine, cursorColumn) -- (line, column)]
    // needNewLine == false indicates that no newline is added.
    private func addWhitespace(line: Int32, column: Int32, needNewLine!: Bool = true): Unit {
        if (innerComments.size > 0) {
            addInnerComments(line, column, needNewLine: needNewLine)
        }
        addWhitespaceWithoutComment(line, column, needNewLine: needNewLine)
    }

    private func addWhitespaceWithoutComment(line: Int32, column: Int32, needNewLine!: Bool = true): Unit {
        var scol = column // default no spaces needed
        if (cursorLine == line) {
            scol = cursorColumn // the same line
        } else if (cursorLine < line) {
            scol = 1 // add current column - 1 spaces
            if (needNewLine) {
                addChild(curChildren, builder.buildNewline(Int64(line - cursorLine)))
            }
        }
        if (column - scol > 0) {
            addChild(curChildren, builder.buildSpace(Int64(column - scol)))
        }
        if (cursorLine < line || (cursorLine == line && cursorColumn <= column)) {
            (cursorLine, cursorColumn) = (line, column)
        }
    }

    private func addWhitespace(curPos: SyntaxFormat_Position, needNewLine!: Bool = true) {
        addWhitespace(curPos.line, curPos.column, needNewLine: needNewLine)
    }

    private func moveCursorColumn(pos: SyntaxFormat_Position, offset: Int64) {
        (cursorLine, cursorColumn) = (pos.line, pos.column + Int32(offset))
    }

    private func moveCursorColumn(col!: Int32 = 1) {
        cursorColumn += col
    }

    private func moveCursorLine(line!: Int32 = 1) {
        cursorColumn = 1
        cursorLine += 1
    }

    private func moveCursorToBegin(base: ?SyntaxFormat_NodeBase) {
        if (let Some(node) <- base) {
            let begin = node.GetBegin()
            // move cursor
            (cursorLine, cursorColumn) = (begin.line, begin.column)
        }
    }

    private func addWhitespaceAndMoveCursorToBegin(base: ?SyntaxFormat_NodeBase) {
        if (let Some(node) <- base) {
            let begin = getNodeCommentBeginPos(node)
            addWhitespaceAndMoveCursor(begin)
        }
    }

    private func getNodeCommentBeginPos(base: SyntaxFormat_NodeBase) {
        var begin = base.GetBegin()
        if (let Some(comments) <- base.GetComments()) {
            let leadComments = comments.GetLeadingComments()
            if (let Some(startPos) <- getCommentGroupListBeginPos(leadComments)) {
                begin = startPos
            }
        }
        begin
    }

    private func moveCursorToEnd(base: ?SyntaxFormat_NodeBase) {
        if (let Some(node) <- base) {
            let end = node.GetEnd()
            // Prevent position rollback
            if (cursorLine < end.line || (cursorLine == end.line && cursorColumn < end.column)) {
                (cursorLine, cursorColumn) = (end.line, end.column)
            }
        }
    }

    private func addWhitespaceAndMoveCursorToEnd(base: ?SyntaxFormat_NodeBase) {
        if (let Some(node) <- base) {
            let end = node.GetEnd()
            addWhitespace(end.line, end.column - 1)
            // move cursor
            (cursorLine, cursorColumn) = (end.line, end.column)
        }
    }

    private func addWhitespaceAndMoveCursor(curPos: SyntaxFormat_Position, needNewLine!: Bool = true) {
        addWhitespace(curPos, needNewLine: needNewLine)
        if (cursorLine < curPos.line || (cursorLine == curPos.line && cursorColumn <= curPos.column)) {
            (cursorLine, cursorColumn) = (curPos.line, curPos.column)
        }
    }

    private func moveCursorString(pos: SyntaxFormat_Position, str: String) {
        var strSplit = str.replace("\r\n", "\n").split("\n")
        if (strSplit.size > 1) {
            // The string contains newline characters; first, move the cursor line,
            // and the column position is determined by the last line of the string.
            cursorLine = pos.line + Int32(strSplit.size) - 1
            cursorColumn = Int32(strSplit[strSplit.size - 1].size + 1)
        } else {
            // The string is single line, simply move the column.
            (cursorLine, cursorColumn) = (pos.line, pos.column + Int32(str.size))
        }
    }

    private func resetGlobalVariables(ret: ArrayList<SyntaxNodeImpl>, innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        curChildren = ret
        innerComments = innerCmts
    }

    private func getSyntaxImplKind(num: UInt16): SyntaxNodeKind {
        match (num) {
            case 8 /*EXP*/ => SyntaxNodeKind.ExpToken
            case 9 /*MUL*/ => SyntaxNodeKind.MulToken
            case 10 /*MOD*/ => SyntaxNodeKind.ModToken
            case 11 /*DIV*/ => SyntaxNodeKind.DivToken
            case 12 /*ADD*/ => SyntaxNodeKind.AddToken
            case 13 /*SUB*/ => SyntaxNodeKind.SubToken
            case 14 /*INCR*/ => SyntaxNodeKind.IncrToken
            case 15 /*DECR*/ => SyntaxNodeKind.DecrToken
            case 16 /*AND*/ => SyntaxNodeKind.AndToken
            case 17 /*OR*/ => SyntaxNodeKind.OrToken
            case 18 /*COALESCING  */ => SyntaxNodeKind.CoalescingToken
            case 19 /*PIPELINE*/ => SyntaxNodeKind.PipelineToken
            case 20 /*COMPOSITION */ => SyntaxNodeKind.CompositionToken
            case 21 /*NOT*/ => SyntaxNodeKind.NotToken
            case 22 /*BITAND*/ => SyntaxNodeKind.BitAndToken
            case 23 /*BITOR */ => SyntaxNodeKind.BitOrToken
            case 24 /*BITXOR*/ => SyntaxNodeKind.BitXorToken
            case 25 /*BITNOT*/ => SyntaxNodeKind.BitNotToken
            case 26 /*LSHIFT*/ => SyntaxNodeKind.LShiftToken
            case 27 /*RSHIFT*/ => SyntaxNodeKind.RShiftToken
            case 30 /*ASSIGN*/ => SyntaxNodeKind.AssignToken
            case 31 /*ADDASSIGN*/ => SyntaxNodeKind.AddAssignToken
            case 32 /*SUBASSIGN*/ => SyntaxNodeKind.SubAssignToken
            case 34 /*EXPASSIGN*/ => SyntaxNodeKind.ExpAssignToken
            case 33 /*MULASSIGN*/ => SyntaxNodeKind.MulAssignToken
            case 35 /*DIVASSIGN*/ => SyntaxNodeKind.DivAssignToken
            case 36 /*MODASSIGN*/ => SyntaxNodeKind.ModAssignToken
            case 37 /*ANDASSIGN*/ => SyntaxNodeKind.AndAssignToken
            case 38 /*ORASSIGN*/ => SyntaxNodeKind.OrAssignToken
            case 39 /*BITANDASSIGN*/ => SyntaxNodeKind.BitAndAssignToken
            case 40 /*BITORASSIGN*/ => SyntaxNodeKind.BitOrAssignToken
            case 41 /*BITXORASSIGN*/ => SyntaxNodeKind.BitXorAssignToken
            case 42 /*LSHIFTASSIGN*/ => SyntaxNodeKind.LShiftAssignToken
            case 43 /*RSHIFTASSIGN*/ => SyntaxNodeKind.RShiftAssignToken
            case 53 /*LT*/ => SyntaxNodeKind.LtToken
            case 54 /*GT*/ => SyntaxNodeKind.GtToken
            case 55 /*LE*/ => SyntaxNodeKind.LeToken
            case 56 /*GE*/ => SyntaxNodeKind.GeToken
            case 59 /*NOTEQ*/ => SyntaxNodeKind.NotEqToken
            case 60 /*EQUAL*/ => SyntaxNodeKind.EqualToken
            case 93 /*CONST*/ => SyntaxNodeKind.ConstToken
            case 118 /*STATIC*/ => SyntaxNodeKind.StaticToken
            case 119 /*PUBLIC*/ => SyntaxNodeKind.PublicToken
            case 120 /*PRIVATE*/ => SyntaxNodeKind.PrivateToken
            case 121 /*INTERNAL*/ => SyntaxNodeKind.InternalToken
            case 122 /*PROTECTED*/ => SyntaxNodeKind.ProtectedToken
            case 123 /*OVERRIDE*/ => SyntaxNodeKind.OverrideToken
            case 124 /*REDEF*/ => SyntaxNodeKind.RedefToken
            case 125 /*ABSTRACT*/ => SyntaxNodeKind.AbstractToken
            case 126 /*SEALED*/ => SyntaxNodeKind.SealedToken
            case 127 /*OPEN*/ => SyntaxNodeKind.OpenToken
            case 128 /*FOREIGN*/ => SyntaxNodeKind.ForeignToken
            case 129 /*INOUT*/ => SyntaxNodeKind.InoutToken
            case 130 /*MUT*/ => SyntaxNodeKind.MutToken
            case 131 /*UNSAFE*/ => SyntaxNodeKind.UnsafeToken
            case 132 /*OPERATOR*/ => SyntaxNodeKind.OperatorToken
            case _ => SyntaxNodeKind.Invalid
        }
    }

    private func isValidPosition(pos: SyntaxFormat_Position): Bool {
        if (pos.line == 0 && pos.column == 0) {
            return false
        }
        return true
    }

    private func isSamePosition(pos1: SyntaxFormat_Position, pos2: SyntaxFormat_Position) {
        return pos1.fileId == pos2.fileId && pos1.line == pos2.line && pos1.column == pos2.column
    }

    // add expr to curNode
    private func transNoTerminalExpr(expr: SyntaxFormat_Expr, isInterpol!: Bool = false) {
        addWhitespaceAndMoveCursorToBegin(expr.GetBase())
        addChild(curChildren, transExpr(expr, [], isInterpol: isInterpol))
        moveCursorToEnd(expr.GetBase())
    }

    // add type to curNode,  startFromBegin = false indicates translate from the TypePos of the type.
    private func transType(ty: SyntaxFormat_Type, startFromBegin!: Bool = true) {
        if (let Some(tyBase) <- ty.GetBase()) {
            if (!startFromBegin) {
                let beginPos = tyBase.GetTypePos()
                addWhitespaceAndMoveCursor(beginPos)
            } else {
                addWhitespaceAndMoveCursorToBegin(tyBase.GetBase())
            }
            addChild(curChildren, transTypeAnnotation(ty))
            moveCursorToEnd(tyBase.GetBase())
        }
    }

    // add basic terminal to curNode
    private func transBasicTerminal(begin: SyntaxFormat_Position, kind: SyntaxNodeKind) {
        if (isValidPosition(begin)) {
            // add prefix whitespace
            addWhitespace(begin)
            // add basic terminal
            addChild(curChildren, builder.buildBasicTerminal(kind))
            // move cursor
            moveCursorColumn(begin, kind.toString().size)
        }
    }

    private func transTokenTerminal(begin: SyntaxFormat_Position, kind: TokenKind, value: String,
        needNewLine!: Bool = true, delimiterNum!: UInt32 = 0, isSingleQuote!: Bool = false, hasEscape!: Bool = false) {
        if (!isValidPosition(begin)) {
            return
        }
        // add prefix whitespace
        addWhitespace(begin, needNewLine: needNewLine)
        var quoteToken = builder.buildQuote(isSingleQuote)
        let tokenValue = builder.buildTokenTerminal(kind, value, hasEscape: hasEscape)
        let valueEscaped = tokenValue.toString()
        var moveStr = valueEscaped
        // add Token terminal, handle strings and character types separately.
        if (kind == TokenKind.MULTILINE_RAW_STRING) {
            let hashToken = builder.buildHash(Int64(delimiterNum))
            curChildren.add(all: [hashToken, quoteToken, tokenValue, quoteToken, hashToken])
            moveStr = '#' * Int64(delimiterNum) + '"' + valueEscaped + '"' + '#' * Int64(delimiterNum)
        } else if (kind == TokenKind.MULTILINE_STRING) {
            quoteToken = builder.buildTripleQuote(isSingleQuote)
            curChildren.add(all: [quoteToken, builder.buildNewline(1), tokenValue, quoteToken])
            moveStr = "'''\n" + valueEscaped + "'''"
        } else if (kind == TokenKind.STRING_LITERAL || kind == TokenKind.SINGLE_QUOTED_STRING_LITERAL) {
            curChildren.add(all: [quoteToken, tokenValue, quoteToken])
            moveStr = "'" + valueEscaped + "'"
        } else if (kind == RUNE_LITERAL) {
            let prefix = builder.buildBasicTerminal(SyntaxNodeKind.RunePrefixToken)
            curChildren.add(all: [prefix, quoteToken, tokenValue, quoteToken])
            moveStr = "r'" + valueEscaped + "'"
        } else {
            curChildren.add(tokenValue)
        }

        // move cursor
        moveCursorString(begin, moveStr)
    }

    // add identifier to curNode
    private func transIdentifier(idPos: SyntaxFormat_Position, id: String) {
        if (isValidPosition(idPos)) {
            addWhitespace(idPos)
            addChild(curChildren, builder.buildValuedTerminal(SyntaxNodeKind.IdentToken, id))
            moveCursorColumn(idPos, id.size)
        }
    }

    private func transImportContent(content: SyntaxFormat_ImportContent): ?SyntaxNodeImpl {
        let (kind, nodeKind) = match (content.GetKind()) {
            case ImportKind_IMPORT_SINGLE => (ImportKind.Single, SyntaxNodeKind.ImportSingle)
            case ImportKind_IMPORT_ALIAS => (ImportKind.Alias, SyntaxNodeKind.ImportAlias)
            case ImportKind_IMPORT_ALL => (ImportKind.All, SyntaxNodeKind.ImportAll)
            case ImportKind_IMPORT_MULTI => (ImportKind.Multi, SyntaxNodeKind.ImportMulti)
        }
        addWhitespaceAndMoveCursorToBegin(content.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = content.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)

        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let prefixPaths = content.GetPrefixPaths()
        let prefixPoses = content.GetPrefixPoses()
        let prefixDotPoses = content.GetPrefixDotPoses()
        for (i in 0..prefixPaths.size) {
            if (let Some(path) <- prefixPaths[i]) {
                transIdentifier(prefixPoses[i], path)
            }
            transBasicTerminal(prefixDotPoses[i], SyntaxNodeKind.DotToken)
        }
        let identPos = content.GetIdentifierPos()
        if (let ImportKind.All <- kind) {
            transBasicTerminal(identPos, SyntaxNodeKind.MulToken)
        } else if (let ImportKind.Multi <- kind) {
            transBasicTerminal(content.GetLeftCurlPos(), SyntaxNodeKind.LCurlToken)

            let vItems = content.GetItems()
            let commaPoses = content.GetCommaPoses()
            for (i in 0..vItems.size) {
                if (let Some(content) <- vItems[i]) {
                    addChild(ret, transImportContent(content))
                    resetGlobalVariables(ret, innerCmts)
                }
                if (i < commaPoses.size) {
                    transBasicTerminal(commaPoses[i], SyntaxNodeKind.CommaToken)
                }
            }
            transBasicTerminal(content.GetRightCurlPos(), SyntaxNodeKind.RCurlToken)
        } else {
            transIdentifier(identPos, content.GetIdentifier())
            if (let ImportKind.Alias <- kind) {
                transBasicTerminal(content.GetAsPos(), SyntaxNodeKind.AsToken)
                transIdentifier(content.GetAsIdentifierPos(), content.GetAsIdentifier())
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(nodeKind, ret.toArray())
    }

    private func transImportList(imports: SyntaxFormat_ImportSpec): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(imports.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = imports.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let kind = match (imports.GetReExport()) {
            case ReExportKind_REEXPORT_PUBLIC => SyntaxNodeKind.PublicToken
            case ReExportKind_REEXPORT_PROTECTED => SyntaxNodeKind.ProtectedToken
            case ReExportKind_REEXPORT_INTERNAL => SyntaxNodeKind.InternalToken
            case _ => SyntaxNodeKind.PrivateToken
        }
        if (let Some(base) <- imports.GetBase()) {
            if (!isSamePosition(imports.GetImportPos(), base.GetBegin())) {
                addChild(ret, transModifier(base.GetBegin(), kind))
                resetGlobalVariables(ret, innerCmts)
            }
        }
        transBasicTerminal(imports.GetImportPos(), SyntaxNodeKind.ImportToken)
        if (let Some(v) <- imports.GetContent()) {
            addChild(ret, transImportContent(v))
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ImportSpec, ret.toArray())
    }

    private func getPrimitiveTypeKind(num: UInt16): SyntaxNodeKind {
        match (num) {
            case 1 /*UNIT*/ => SyntaxNodeKind.UnitToken
            case 2 /*INT8*/ => SyntaxNodeKind.Int8Token
            case 3 /*INT16*/ => SyntaxNodeKind.Int16Token
            case 4 /*INT32*/ => SyntaxNodeKind.Int32Token
            case 5 /*INT64*/ => SyntaxNodeKind.Int64Token
            case 6 /*INTNATIVE*/ => SyntaxNodeKind.IntNativeToken
            case 8 /*UINT8*/ => SyntaxNodeKind.UInt8Token
            case 9 /*UINT16*/ => SyntaxNodeKind.UInt16Token
            case 10 /*UINT32*/ => SyntaxNodeKind.UInt32Token
            case 11 /*UINT64*/ => SyntaxNodeKind.UInt64Token
            case 12 /*UINTNATIVE*/ => SyntaxNodeKind.UIntNativeToken
            case 13 /*FLOAT16*/ => SyntaxNodeKind.Float16Token
            case 14 /*FLOAT32*/ => SyntaxNodeKind.Float32Token
            case 15 /*FLOAT64*/ => SyntaxNodeKind.Float64Token
            case 17 /*RUNE*/ => SyntaxNodeKind.RuneToken
            case 18 /*NOTHING*/ => SyntaxNodeKind.NothingToken
            case 19 /*BOOLEAN*/ => SyntaxNodeKind.BooleanToken
            case _ => return SyntaxNodeKind.Invalid
        }
    }

    private func transPrimitiveTypeExpr(primitiveType: SyntaxFormat_PrimitiveTypeExpr): ?SyntaxNodeImpl {
        return transPrimitiveTypeNode(primitiveType.GetBase(), primitiveType.GetKind(), false)
    }

    private func transPrimitiveType(primitiveType: SyntaxFormat_PrimitiveType): ?SyntaxNodeImpl {
        return transPrimitiveTypeNode(primitiveType.GetBase().getOrThrow().GetBase(), primitiveType.GetKind(), true)
    }

    private func transPrimitiveTypeNode(nodeBase: ?SyntaxFormat_NodeBase, primitiveKind: UInt16,
        addPendingTrailComments: Bool): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let ty = getPrimitiveTypeKind(primitiveKind)
        addChild(ret, builder.buildBasicTerminal(ty))
        moveCursorColumn(col: Int32(ty.size))
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        if (addPendingTrailComments) {
            addTrailCommentNodesToRet(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.PrimitiveType, ret.toArray())
    }

    private func transRefType(ty: SyntaxFormat_RefType): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = ty.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(ref) <- ty.GetRef()) {
            transIdentifier(ref.GetIdentifierPos(), ref.GetIdentifier())
        }
        let typeArguments = ty.GetTypeArguments()
        if (typeArguments.size != 0) {
            addChild(ret, transTypeArguments(typeArguments, ty.GetLeftAnglePos(), ty.GetRightAnglePos()))
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.RefType, ret.toArray())
    }

    private func transTypeElementWithOptionalLabel(type_: SyntaxFormat_Type, ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        if (let Some(db) <- type_.GetBase()) {
            var startFromBegin = true
            if (isValidPosition(db.GetColonPos()) && let Some(base) <- db.GetBase()) {
                transIdentifier(base.GetBegin(), db.GetTypeParameterName())
                transBasicTerminal(db.GetColonPos(), SyntaxNodeKind.ColonToken)
                startFromBegin = false
            }
            transType(type_, startFromBegin: startFromBegin)
            resetGlobalVariables(ret, innerCmts)
            transBasicTerminal(db.GetCommaPos(), SyntaxNodeKind.CommaToken)
        }
    }

    private func transFuncType(ty: SyntaxFormat_FuncType): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = ty.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(ty.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        let types = ty.GetParamTypes()
        for (t in types) {
            if (let Some(type_) <- t) {
                transTypeElementWithOptionalLabel(type_, ret, innerCmts)
            }
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(ty.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        transBasicTerminal(ty.GetArrowPos(), SyntaxNodeKind.ArrowToken)
        if (let Some(t) <- ty.GetRetType()) {
            transType(t)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.FuncType, ret.toArray())
    }

    private func transThisType(ty: SyntaxFormat_ThisType): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = ty.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        addChild(ret, builder.buildBasicTerminal(SyntaxNodeKind.ThisTypeToken))
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.PrimitiveType, ret.toArray())
    }

    private func transTupleType(ty: SyntaxFormat_TupleType): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = ty.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(ty.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        let types = ty.GetFieldTypes()
        for (t in 0..types.size) {
            if (let Some(type_) <- types[t]) {
                transTypeElementWithOptionalLabel(type_, ret, innerCmts)
            }
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(ty.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TupleType, ret.toArray())
    }

    private func transInnerOptionType(questVec: Array<SyntaxFormat_Position>, i: Int64, ty: SyntaxFormat_Type): ?SyntaxNodeImpl {
        if (questVec.size == i) {
            if (let Some(tyBase) <- ty.GetBase()) {
                addWhitespaceAndMoveCursorToBegin(tyBase.GetBase())
                let ret = transTypeAnnotation(ty)
                return ret
            }
            return None
        } else {
            addWhitespace(questVec[i])
            let ret = ArrayList<SyntaxNodeImpl>()
            addLeadCommentNodesToRet(ret)
            curChildren = ret

            let nodeBase = ty.GetBase().getOrThrow().GetBase()
            let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
            addLeadingComments(nodeBase, ret, leadCmts)
            innerComments = innerCmts

            ret.add(builder.buildBasicTerminal(SyntaxNodeKind.QuestToken))
            moveCursorColumn(questVec[i], 1)
            addChild(ret, transInnerOptionType(questVec, i + 1, ty))
            if (trailCmts.size > 0) {
                addChild(ret, transCommentGroupList(trailCmts))
                curChildren = ret
            }
            addTrailCommentNodesToRet(ret, innerCmts)
            return builder.buildNonTerminal(SyntaxNodeKind.OptionType, ret.toArray())
        }
    }

    private func transOptionType(ty: SyntaxFormat_OptionType): ?SyntaxNodeImpl {
        let questVec = ty.GetQuestVector()
        let questNum = questVec.size
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        addWhitespace(questVec[0])
        curChildren = ret

        let nodeBase = ty.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        ret.add(builder.buildBasicTerminal(SyntaxNodeKind.QuestToken))
        moveCursorColumn(questVec[0], 1)
        if (let Some(t) <- ty.GetComponentType()) {
            if (let Some(tyBase) <- t.GetBase()) {
                addChild(ret, transInnerOptionType(questVec, 1, t))
                moveCursorToEnd(tyBase.GetBase())
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        return builder.buildNonTerminal(SyntaxNodeKind.OptionType, ret.toArray())
    }

    private func transParenType(parenType: SyntaxFormat_ParenType): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = parenType.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(parenType.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        if (let Some(ty) <- parenType.GetType()) {
            transType(ty)
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(parenType.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ParenType, ret.toArray())
    }

    private func transBaseIdentTokens(ty: SyntaxFormat_Type): Unit {
        let table = ty.table
        let o: UInt16 = table.offset(ty.TYPE)
        let off: UInt32 = UInt32(o) + table.pos
        let ret = curChildren
        match (ty.GetTypeType()) {
            case AnyType_REF_TYPE =>
                if (let Some(ref) <- SyntaxFormat_RefType(table.bytes, off).GetRef()) {
                    transIdentifier(ref.GetIdentifierPos(), ref.GetIdentifier())
                }
            case AnyType_QUALIFIED_TYPE =>
                let qualifiedType = SyntaxFormat_QualifiedType(table.bytes, off)
                if (let Some(baseTy) <- qualifiedType.GetBaseType()) {
                    transBaseIdentTokens(baseTy)
                    curChildren = ret
                }
                transBasicTerminal(qualifiedType.GetDotPos(), SyntaxNodeKind.DotToken)
                transIdentifier(qualifiedType.GetFieldPos(), qualifiedType.GetField())
            case _ => throw Exception("ParseException: error trans base identToken")
        }
    }

    private func transQualifiedType(qualifiedType: SyntaxFormat_QualifiedType): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = qualifiedType.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(baseTy) <- qualifiedType.GetBaseType()) {
            transBaseIdentTokens(baseTy)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(qualifiedType.GetDotPos(), SyntaxNodeKind.DotToken)
        transIdentifier(qualifiedType.GetFieldPos(), qualifiedType.GetField())
        let typeArguments = qualifiedType.GetTypeArguments()
        if (typeArguments.size != 0) {
            addChild(ret,
                transTypeArguments(typeArguments, qualifiedType.GetLeftAnglePos(), qualifiedType.GetRightAnglePos()))
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.QualifiedType, ret.toArray())
    }

    // only use in transVArrayType
    private func transConstantType(constantTy: SyntaxFormat_ConstantType): ?SyntaxNodeImpl {
        transBasicTerminal(constantTy.GetDollarPos(), SyntaxNodeKind.DollarToken)
        if (let Some(constantExpr) <- constantTy.GetConstantExpr()) {
            transNoTerminalExpr(constantExpr)
        }
        None
    }

    private func transVArrayType(vArrayType: SyntaxFormat_VArrayType): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = vArrayType.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(vArrayType.GetVarrayPos(), SyntaxNodeKind.VArrayToken)
        transBasicTerminal(vArrayType.GetLeftAnglePos(), SyntaxNodeKind.LtToken)
        if (let Some(ty) <- vArrayType.GetTypeArgument()) {
            transType(ty)
            resetGlobalVariables(ret, innerCmts)
            if (let Some(tb) <- ty.GetBase()) {
                transBasicTerminal(tb.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
        }
        if (let Some(constantTy) <- vArrayType.GetConstantType()) {
            transTypeAnnotation(constantTy)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(vArrayType.GetRightAnglePos(), SyntaxNodeKind.GtToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        addTrailCommentNodesToRet(ret, innerCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.VArrayType, ret.toArray())
    }

    private func transTypeAnnotation(ty: SyntaxFormat_Type): ?SyntaxNodeImpl {
        let table = ty.table
        let o: UInt16 = table.offset(ty.TYPE)
        let off: UInt32 = UInt32(o) + table.pos
        match (ty.GetTypeType()) {
            case AnyType_PRIMITIVE_TYPE => transPrimitiveType(SyntaxFormat_PrimitiveType(table.bytes, off))
            case AnyType_REF_TYPE => transRefType(SyntaxFormat_RefType(table.bytes, off))
            case AnyType_FUNC_TYPE => transFuncType(SyntaxFormat_FuncType(table.bytes, off))
            case AnyType_THIS_TYPE => transThisType(SyntaxFormat_ThisType(table.bytes, off))
            case AnyType_PAREN_TYPE => transParenType(SyntaxFormat_ParenType(table.bytes, off))
            case AnyType_QUALIFIED_TYPE => transQualifiedType(SyntaxFormat_QualifiedType(table.bytes, off))
            case AnyType_OPTION_TYPE => transOptionType(SyntaxFormat_OptionType(table.bytes, off))
            case AnyType_TUPLE_TYPE => transTupleType(SyntaxFormat_TupleType(table.bytes, off))
            case AnyType_CONSTANT_TYPE => transConstantType(SyntaxFormat_ConstantType(table.bytes, off))
            case AnyType_VARRAY_TYPE => transVArrayType(SyntaxFormat_VArrayType(table.bytes, off))
            case _ => throw Exception("ParseException: The current version does not support this node.")
        }
    }

    /* translate funcs*/
    private func transFile(file: SyntaxFormat_File): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = file.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(featuresNode) <- file.GetFeature()) {
            addChild(ret, transFeaturesDirective(featuresNode))
            resetGlobalVariables(ret, innerCmts)
        }

        if (let Some(packageNode) <- file.GetPackage()) {
            addChild(ret, transPackageSpec(packageNode))
            resetGlobalVariables(ret, innerCmts)
        }
        let imports = file.GetImports()
        for (imp in imports) {
            if (let Some(import1) <- imp) {
                addChild(ret, transImportList(import1))
                resetGlobalVariables(ret, innerCmts)
            }
        }

        let decls: Array<Option<SyntaxFormat_Decl>> = file.GetDecls()
        for (node in decls) {
            resetGlobalVariables(ret, innerCmts) // set context node
            if (let Some(decl) <- node) {
                addChild(ret, transDecl(decl))
            }
        }
        resetGlobalVariables(ret, innerCmts)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.File, ret.toArray())
    }

    private func transFeatureId(ftr: SyntaxFormat_FeatureId): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(ftr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let idents = ftr.GetIdentifiers()
        let identPoses = ftr.GetIdentPoses()
        let dotPoses = ftr.GetDotPoses()
        for (i in 0..idents.size) {
            if (let Some(item) <- idents[i]) {
                transIdentifier(identPoses[i], item)
            }
            if (i < dotPoses.size) {
                transBasicTerminal(dotPoses[i], SyntaxNodeKind.DotToken)
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.FeatureId, ret.toArray())
    }

    private func transFeaturesSet(ftrSet: SyntaxFormat_FeaturesSet): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(ftrSet.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let lCurlPos = ftrSet.GetLCurlPos()
        let rCurlPos = ftrSet.GetRCurlPos()
        let content = ftrSet.GetContent()
        let commaPoses = ftrSet.GetCommaPoses()
        transBasicTerminal(lCurlPos, SyntaxNodeKind.LCurlToken)
        for (i in 0..content.size) {
            if (let Some(item) <- content[i]) {
                addChild(ret, transFeatureId(item))
                curChildren = ret
            }
            if (i < commaPoses.size) {
                transBasicTerminal(commaPoses[i], SyntaxNodeKind.CommaToken)
            }
        }
        transBasicTerminal(rCurlPos, SyntaxNodeKind.RCurlToken)
        builder.buildNonTerminal(SyntaxNodeKind.FeaturesSet, ret.toArray())
    }
    
    private func transFeaturesDirective(ftr: SyntaxFormat_FeaturesDirective): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(ftr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        curChildren = ret

        let annos = ftr.GetAnnotations()
        if (annos.size != 0) {
            addChild(ret, transAnnotations(annos))
        } else {
            addWhitespaceAndMoveCursorToBegin(ftr.GetBase())
        }
        transBasicTerminal(ftr.GetFeaturesPos(), SyntaxNodeKind.FeaturesToken)
        if (let Some(ftrSet) <- ftr.GetFeaturesSet()) {
            addChild(ret, transFeaturesSet(ftrSet))
        }
        builder.buildNonTerminal(SyntaxNodeKind.FeaturesDirective, ret.toArray())
    }

    private func getPackageIndentKind(s: String): SyntaxNodeKind {
        let isPkgIdent = s.contains(".") || s.contains("-") || s.contains(" ")
        if (isPkgIdent) {
            return SyntaxNodeKind.PackageIdentifierToken
        } else {
            return SyntaxNodeKind.IdentToken
        }
    }

    private func transPackagePrefixes(prefixPaths: Array<Option<String>>, prefixPoses: Array<SyntaxFormat_Position>,
        prefixDotPoses: Array<SyntaxFormat_Position>): ?SyntaxNodeImpl {
        if (prefixPaths.size != prefixPoses.size || prefixPaths.size != prefixDotPoses.size) {
            return None
        }
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        for (i in 0..prefixPaths.size) {
            addWhitespace(prefixPoses[i])
            curChildren = ret
            if (let Some(prefixPath) <- prefixPaths[i]) {
                ret.add(builder.buildValuedTerminal(getPackageIndentKind(prefixPath), prefixPath))
                moveCursorColumn(prefixPoses[i], prefixPath.size)
            }
            transBasicTerminal(prefixDotPoses[i], SyntaxNodeKind.DotToken)
        }
        builder.buildNonTerminal(SyntaxNodeKind.PackagePrefixes, ret.toArray())
    }

    private func transPackageSpec(pkg: SyntaxFormat_PackageSpec): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(pkg.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = pkg.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(nodeBase) <- pkg.GetBase()) {
            let beginPos = nodeBase.GetBegin()
            if (!isSamePosition(pkg.GetMacroPos(), beginPos) && !isSamePosition(pkg.GetPackagePos(), beginPos)) {
                let kind = match (pkg.GetAccessible()) {
                    case SyntaxFormat_AccessibleKind.AccessibleKind_ACCESSIBLE_PUBLIC => SyntaxNodeKind.PublicToken
                    case SyntaxFormat_AccessibleKind.AccessibleKind_ACCESSIBLE_PROTECTED => SyntaxNodeKind.ProtectedToken
                    case _ => SyntaxNodeKind.InternalToken
                }
                addChild(ret, transModifier(beginPos, kind))
                resetGlobalVariables(ret, innerCmts)
            }
        }
        transBasicTerminal(pkg.GetMacroPos(), SyntaxNodeKind.MacroToken)
        transBasicTerminal(pkg.GetPackagePos(), SyntaxNodeKind.PackageToken)
        let prefixPaths = pkg.GetPrefixPaths()
        if (prefixPaths.size != 0) {
            addChild(ret, transPackagePrefixes(prefixPaths, pkg.GetPrefixPoses(), pkg.GetPrefixDotPoses()))
        }
        resetGlobalVariables(ret, innerCmts)
        addWhitespace(pkg.GetPackageNamePos())
        let packageName = pkg.GetPackageName()
        ret.add(builder.buildValuedTerminal(getPackageIndentKind(packageName), packageName))
        moveCursorColumn(pkg.GetPackageNamePos(), packageName.size)

        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.PackageSpec, ret.toArray())
    }

    // Decls: 
    private func transDecl(decl: SyntaxFormat_Decl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let table = decl.table
        let o: UInt16 = table.offset(decl.DECL)
        let off: UInt32 = UInt32(o) + table.pos
        match (decl.GetDeclType()) {
            case AnyDecl_VAR_DECL => transVarDecl(SyntaxFormat_VarDecl(table.bytes, off), preChildren)
            case AnyDecl_MAIN_DECL => transMainDecl(SyntaxFormat_MainDecl(table.bytes, off), preChildren)
            case AnyDecl_FUNC_DECL => transFuncDecl(SyntaxFormat_FuncDecl(table.bytes, off), preChildren)
            case AnyDecl_TYPE_ALIAS_DECL => transTypeAlias(SyntaxFormat_TypeAliasDecl(table.bytes, off), preChildren)
            case AnyDecl_CLASS_DECL => transClassDecl(SyntaxFormat_ClassDecl(table.bytes, off), preChildren)
            case AnyDecl_STRUCT_DECL => transStructDecl(SyntaxFormat_StructDecl(table.bytes, off), preChildren)
            case AnyDecl_ENUM_DECL => transEnumDecl(SyntaxFormat_EnumDecl(table.bytes, off), preChildren)
            case AnyDecl_EXTEND_DECL => transExtendDecl(SyntaxFormat_ExtendDecl(table.bytes, off), preChildren)
            case AnyDecl_INTERFACE_DECL => transInterfaceDecl(SyntaxFormat_InterfaceDecl(table.bytes, off), preChildren)
            case AnyDecl_PROP_DECL => transPropDecl(SyntaxFormat_PropDecl(table.bytes, off), preChildren)
            case AnyDecl_PRIMARY_CTOR_DECL => transPrimaryCtorDecl(SyntaxFormat_PrimaryCtorDecl(table.bytes, off),
                preChildren)
            case AnyDecl_MACRO_DECL => transMacroDecl(SyntaxFormat_MacroDecl(table.bytes, off), preChildren)
            case AnyDecl_VAR_WITH_PATTERN_DECL => transVarWithPatternDecl(
                SyntaxFormat_VarWithPatternDecl(table.bytes, off), preChildren)
            case AnyDecl_FUNC_PARAM => transFuncParam(SyntaxFormat_FuncParam(table.bytes, off), preChildren)
            case AnyDecl_MACRO_EXPAND_DECL => transMacroExpandDecl(SyntaxFormat_MacroExpandDecl(table.bytes, off),
                preChildren)
            case _ => throw Exception("ParseException: The current version does not support this node.")
        }
    }

    private func transAnnotation(annotation: SyntaxFormat_Annotation): ?SyntaxNodeImpl {
        /* frist node add space to parentNode,*/
        addWhitespaceAndMoveCursorToBegin(annotation.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = annotation.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(nb) <- annotation.GetBase()) {
            let atKind = if (annotation.GetIsCompileTimeVisible()) {
                transBasicTerminal(nb.GetBegin(), SyntaxNodeKind.AtExclToken)
            } else {
                transBasicTerminal(nb.GetBegin(), SyntaxNodeKind.AtToken)
            }
        }
        transIdentifier(annotation.GetIdentPos(), annotation.GetIdentifier())
        transBasicTerminal(annotation.GetLeftSquarePos(), SyntaxNodeKind.LSquareToken)
        for (p in annotation.GetArgs()) {
            if (let Some(arg) <- p) {
                addWhitespaceAndMoveCursorToBegin(arg.GetBase())
                addChild(ret, transFuncArg(arg))
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(arg.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
        }
        if (let Some(cond) <- annotation.GetCondExpr()) {
            addWhitespaceAndMoveCursorToBegin(cond.GetBase())
            let argRet = ArrayList<SyntaxNodeImpl>()
            curChildren = argRet
            transNoTerminalExpr(cond)
            resetGlobalVariables(ret, innerCmts)
            addChild(ret, builder.buildNonTerminal(SyntaxNodeKind.Argument, argRet.toArray()))
        }
        let attrs = annotation.GetAttrs()
        let attrCommasPos = annotation.GetAttrCommasPos()
        for (i in 0..attrs.size) {
            if (let Some(v) <- attrs[i]) {
                let curPos = v.GetPos()
                addWhitespaceAndMoveCursor(curPos)
                let cur = match (getTokenKind(v.GetKind())) {
                    case TokenKind.IDENTIFIER =>
                        moveCursorString(curPos, v.GetValue())
                        builder.buildNonTerminal(SyntaxNodeKind.RefExpr,
                            [builder.buildValuedTerminal(SyntaxNodeKind.IdentToken, v.GetValue())])
                    case TokenKind.STRING_LITERAL => buildLineStringLiteral(nodeBase,
                        builder.buildValuedTerminal(SyntaxNodeKind.StringLiteralToken, v.GetValue()),
                        v.GetIsSingleQuote(), [])
                    case _ => builder.buildInvalidTerminal()
                }
                addChild(ret, builder.buildNonTerminal(SyntaxNodeKind.Argument, [cur]))
                if (i < attrCommasPos.size) {
                    transBasicTerminal(attrCommasPos[i], SyntaxNodeKind.CommaToken)
                }
            }
        }
        transBasicTerminal(annotation.GetRightSquarePos(), SyntaxNodeKind.RSquareToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.Annotation, ret.toArray())
    }

    private func transAnnotations(annotations: Array<Option<SyntaxFormat_Annotation>>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        for (annotation in annotations) {
            if (let Some(anno) <- annotation) {
                addChild(ret, transAnnotation(anno))
                curChildren = ret
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.AnnotationList, ret.toArray())
    }

    private func transModifier(begin: SyntaxFormat_Position, kind: SyntaxNodeKind): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        transBasicTerminal(begin, kind)

        builder.buildNonTerminal(SyntaxNodeKind.Modifier, ret.toArray())
    }

    private func transModifier(modifier: SyntaxFormat_Modifier): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(modifier.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = modifier.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let kind = getSyntaxImplKind(modifier.GetKind())
        addChild(ret, builder.buildBasicTerminal(kind))
        moveCursorToEnd(modifier.GetBase())
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.Modifier, ret.toArray())
    }

    private func transModifiers(modifiers: Array<Option<SyntaxFormat_Modifier>>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        for (modifier in modifiers) {
            if (let Some(mod) <- modifier) {
                // first node add space to parentNode
                addChild(ret, transModifier(mod))
                curChildren = ret
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.ModifierList, ret.toArray())
    }

    private func transVarDeclModifiers(modifiers: Array<Option<SyntaxFormat_Modifier>>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        for (modifier in modifiers) {
            if (let Some(mod) <- modifier && getSyntaxImplKind(mod.GetKind()) != SyntaxNodeKind.ConstToken) {
                // first node add space to parentNode())
                addChild(ret, transModifier(mod))
                curChildren = ret
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.ModifierList, ret.toArray())
    }

    private func transVarPattern4VarDecl(varDecl: SyntaxFormat_VarDecl): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()
        if (let Some(db) <- varDecl.GetBase()) {
            addWhitespaceAndMoveCursor(db.GetIdentifierPos())
            curChildren = ret
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
        }
        builder.buildNonTerminal(SyntaxNodeKind.VarBindingPattern, ret.toArray())
    }

    private func prepareVarDeclPrefix(base: Option<SyntaxFormat_DeclBase>) {
        let ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = base.getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- base) {
            // annotation
            let annos = db.GetAnnotations()
            if (annos.size != 0) {
                addChild(ret, transAnnotations(db.GetAnnotations()))
            } else {
                // The begin of variable declaration is not begin of annotations.
                addWhitespaceAndMoveCursorToBegin(db.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)

            // modifier
            let modifiers = db.GetModifiers()
            if (modifiers.size != 0) {
                addChild(ret, transVarDeclModifiers(modifiers))
                resetGlobalVariables(ret, innerCmts)
            }
        }

        return (ret, innerCmts, trailCmts)
    }

    private func appendVarDeclInitializer(initializer: Option<SyntaxFormat_Expr>, assignPos: SyntaxFormat_Position) {
        if (let Some(initializerExpr) <- initializer) {
            transBasicTerminal(assignPos, SyntaxNodeKind.AssignToken)
            transNoTerminalExpr(initializerExpr)
        }
    }

    private func appendTrailingComments(ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>, trailCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
    }

    private func transDeclIdentifierAndTypeParams(db: SyntaxFormat_DeclBase, ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())

        if (let Some(generic) <- db.GetGeneric()) {
            let typeParameters = generic.GetTypeParameters()
            if (typeParameters.size != 0) {
                addChild(ret, transTypeArguments(typeParameters, generic.GetLeftAnglePos(), generic.GetRightAnglePos()))
            }
        }
        resetGlobalVariables(ret, innerCmts)
    }

    private func transDeclAnnotationsAndModifiers(db: SyntaxFormat_DeclBase, ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        let annos = db.GetAnnotations()
        if (annos.size != 0) {
            addChild(ret, transAnnotations(annos))
        } else {
            addWhitespaceAndMoveCursorToBegin(db.GetBase())
        }
        resetGlobalVariables(ret, innerCmts)

        let modifiers = db.GetModifiers()
        if (modifiers.size != 0) {
            addChild(ret, transModifiers(modifiers))
            resetGlobalVariables(ret, innerCmts)
        }
    }

    private func finishFuncBodyBlockAndComments(body: Option<SyntaxFormat_FuncBody>, ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>, trailCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        if (let Some(funcBody) <- body) {
            resetGlobalVariables(ret, innerCmts)
            if (let Some(block) <- funcBody.GetBody()) {
                addChild(ret, transBlock(block))
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
    }

    private func transBitAndSeparatedTypes(types: Array<Option<SyntaxFormat_Type>>, ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        for (i in 0..types.size) {
            if (let Some(ty) <- types[i]) {
                transType(ty)
                resetGlobalVariables(ret, innerCmts)
                if (i < types.size - 1 && let Some(base) <- ty.GetBase()) {
                    transBasicTerminal(base.GetBitAndPos(), SyntaxNodeKind.BitAndToken)
                }
            }
        }
        resetGlobalVariables(ret, innerCmts)
    }

    private func transVarDecl(varDecl: SyntaxFormat_VarDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let (ret, innerCmts, trailCmts) = prepareVarDeclPrefix(varDecl.GetBase())

        if (let Some(db) <- varDecl.GetBase()) {
            if (!varDecl.GetEmptyKeyword()) {
                if (varDecl.GetIsVar()) {
                    transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.VarToken)
                } else if (db.GetIsConst()) {
                    transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.ConstToken)
                } else {
                    transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.LetToken)
                }
            }
            addChild(ret, transVarPattern4VarDecl(varDecl))
            resetGlobalVariables(ret, innerCmts)
            if (let Some(ty) <- varDecl.GetType()) {
                transBasicTerminal(varDecl.GetColonPos(), SyntaxNodeKind.ColonToken)
                transType(ty)
                curChildren = ret
            }
        }
        resetGlobalVariables(ret, innerCmts)
        appendVarDeclInitializer(varDecl.GetInitializer(), varDecl.GetAssignPos())
        appendTrailingComments(ret, innerCmts, trailCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.VarDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transVarWithPatternDecl(varDecl: SyntaxFormat_VarWithPatternDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let (ret, innerCmts, trailCmts) = prepareVarDeclPrefix(varDecl.GetBase())

        if (let Some(db) <- varDecl.GetBase()) {
            if (varDecl.GetIsVar()) {
                transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.VarToken)
            } else if (db.GetIsConst()) {
                transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.ConstToken)
            } else {
                transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.LetToken)
            }
            if (let Some(pattern) <- varDecl.GetPattern()) {
                addChild(ret, transPattern(pattern))
            }
            resetGlobalVariables(ret, innerCmts)
            if (let Some(ty) <- varDecl.GetType()) {
                transBasicTerminal(varDecl.GetColonPos(), SyntaxNodeKind.ColonToken)
                transType(ty)
                resetGlobalVariables(ret, innerCmts)
            }
        }
        resetGlobalVariables(ret, innerCmts)
        appendVarDeclInitializer(varDecl.GetInitializer(), varDecl.GetAssignPos())
        appendTrailingComments(ret, innerCmts, trailCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.VarDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transMainDecl(mainDecl: SyntaxFormat_MainDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = mainDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- mainDecl.GetBase()) {
            addWhitespaceAndMoveCursorToBegin(db.GetBase())
            resetGlobalVariables(ret, innerCmts)
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.MainToken)
        }
        if (let Some(body) <- mainDecl.GetFuncBody()) {
            // functionParameters
            if (let Some(paramList) <- body.GetParamList()) {
                addChild(ret, transParamList(paramList))
                moveCursorToEnd(paramList.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)
            if (let Some(ty) <- body.GetRetType()) {
                transBasicTerminal(body.GetColonPos(), SyntaxNodeKind.ColonToken)
                transType(ty)
                resetGlobalVariables(ret, innerCmts)
            }
            // block
            if (let Some(block) <- body.GetBody()) {
                addChild(ret, transBlock(block))
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MainDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transTypeAlias(typeAlias: SyntaxFormat_TypeAliasDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = typeAlias.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- typeAlias.GetBase()) {
            // annotation
            let annos = db.GetAnnotations()
            if (annos.size != 0) {
                addChild(ret, transAnnotations(db.GetAnnotations()))
            } else {
                // The begin of TypeAlias is not begin of annotations
                addWhitespaceAndMoveCursorToBegin(db.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)
            // modifier
            let modifiers = db.GetModifiers()
            if (modifiers.size != 0) {
                if (!db.GetIsConst() || modifiers.size > 1) {
                    addChild(ret, transModifiers(modifiers))
                    resetGlobalVariables(ret, innerCmts)
                }
            }

            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.TypeToken)
            transDeclIdentifierAndTypeParams(db, ret, innerCmts)
        }

        transBasicTerminal(typeAlias.GetAssignPos(), SyntaxNodeKind.AssignToken)
        if (let Some(ty) <- typeAlias.GetType()) {
            transType(ty)
        }
        resetGlobalVariables(ret, innerCmts)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TypeAlias, ret.toArray(), preChildren: preChildren)
    }

    private func transClassBody(nodeBase: ?SyntaxFormat_NodeBase, decls: Array<Option<SyntaxFormat_Decl>>,
        lcurlPos: SyntaxFormat_Position, rcurlPos: SyntaxFormat_Position): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        addWhitespaceAndMoveCursor(lcurlPos)
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(lcurlPos, SyntaxNodeKind.LCurlToken)

        for (decl in decls) {
            if (let Some(dl) <- decl) {
                addChild(ret, transDecl(dl))
                resetGlobalVariables(ret, innerCmts)
            }
        }
        innerComments = innerCmts
        transBasicTerminal(rcurlPos, SyntaxNodeKind.RCurlToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.Body, ret.toArray())
    }

    private func transClassBody(decls: Array<Option<SyntaxFormat_Decl>>, lcurlPos: SyntaxFormat_Position,
        rcurlPos: SyntaxFormat_Position): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        // add prefix whitespace and move cursor
        addWhitespaceAndMoveCursor(lcurlPos)
        curChildren = ret
        transBasicTerminal(lcurlPos, SyntaxNodeKind.LCurlToken)

        for (decl in decls) {
            if (let Some(dl) <- decl) {
                addChild(ret, transDecl(dl))
                curChildren = ret
            }
        }
        transBasicTerminal(rcurlPos, SyntaxNodeKind.RCurlToken)
        builder.buildNonTerminal(SyntaxNodeKind.Body, ret.toArray())
    }

    private func transPrimaryCtorDecl(primaryCtorDecl: SyntaxFormat_PrimaryCtorDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = primaryCtorDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- primaryCtorDecl.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)

            // identifier
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
        }

        if (let Some(body) <- primaryCtorDecl.GetFuncBody()) {
            if (let Some(paramList) <- body.GetParamList()) {
                addChild(ret, transParamList(paramList))
                moveCursorToEnd(paramList.GetBase())
            }
        }
        finishFuncBodyBlockAndComments(primaryCtorDecl.GetFuncBody(), ret, innerCmts, trailCmts)
        builder.buildNonTerminal(SyntaxNodeKind.FuncDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transClassDecl(classDecl: SyntaxFormat_ClassDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = classDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- classDecl.GetBase()) {
            // annotation
            if (db.GetAnnotations().size != 0) {
                addChild(ret, transAnnotations(db.GetAnnotations()))
            } else {
                addWhitespaceAndMoveCursorToBegin(db.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)
            // modifier
            if (db.GetModifiers().size != 0) {
                addChild(ret, transModifiers(db.GetModifiers()))
                resetGlobalVariables(ret, innerCmts)
            }
            // ClassToken
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.ClassToken)

            // identifier
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())

            if (let Some(generic) <- db.GetGeneric() && generic.GetTypeParameters().size != 0) {
                addChild(ret,
                    transTypeArguments(generic.GetTypeParameters(), generic.GetLeftAnglePos(),
                        generic.GetRightAnglePos()))
            }
            resetGlobalVariables(ret, innerCmts)
        }

        transBasicTerminal(classDecl.GetUpperBoundPos(), SyntaxNodeKind.UpperBoundToken)

        let superTypes = classDecl.GetSuperTypes()
        transBitAndSeparatedTypes(superTypes, ret, innerCmts)

        if (let Some(db) <- classDecl.GetBase() && let Some(generic) <- db.GetGeneric() &&
            generic.GetGenericConstraints().size != 0) {
            addChild(ret, transGenericConstraints(generic.GetGenericConstraints()))
            resetGlobalVariables(ret, innerCmts)
        }

        if (let Some(body) <- classDecl.GetBody()) {
            addChild(ret, transClassBody(body.GetBase(), body.GetDecls(), body.GetLeftCurlPos(), body.GetRightCurlPos()))
            resetGlobalVariables(ret, innerCmts)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ClassDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transStructDecl(structDecl: SyntaxFormat_StructDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = structDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- structDecl.GetBase()) {
            // annotation
            let annos = db.GetAnnotations()
            if (annos.size != 0) {
                addChild(ret, transAnnotations(db.GetAnnotations()))
            } else {
                addWhitespaceAndMoveCursorToBegin(db.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)
            // modifier
            if (db.GetModifiers().size != 0) {
                addChild(ret, transModifiers(db.GetModifiers()))
                resetGlobalVariables(ret, innerCmts)
            }
            // func
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.StructToken)

            // identifier
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())

            if (let Some(generic) <- db.GetGeneric() && generic.GetTypeParameters().size != 0) {
                addChild(ret,
                    transTypeArguments(generic.GetTypeParameters(), generic.GetLeftAnglePos(),
                        generic.GetRightAnglePos()))
            }
            resetGlobalVariables(ret, innerCmts)
        }

        transBasicTerminal(structDecl.GetUpperBoundPos(), SyntaxNodeKind.UpperBoundToken)

        let superTypes = structDecl.GetSuperTypes()
        transBitAndSeparatedTypes(superTypes, ret, innerCmts)

        if (let Some(db) <- structDecl.GetBase() && let Some(generic) <- db.GetGeneric() &&
            generic.GetGenericConstraints().size > 0) {
            addChild(ret, transGenericConstraints(generic.GetGenericConstraints()))
            resetGlobalVariables(ret, innerCmts)
        }

        if (let Some(body) <- structDecl.GetBody()) {
            addChild(ret, transClassBody(body.GetBase(), body.GetDecls(), body.GetLeftCurlPos(), body.GetRightCurlPos()))
            resetGlobalVariables(ret, innerCmts)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.StructDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transInterfaceDecl(interfaceDecl: SyntaxFormat_InterfaceDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = interfaceDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- interfaceDecl.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)
            // func
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.InterfaceToken)
            transDeclIdentifierAndTypeParams(db, ret, innerCmts)
        }

        transBasicTerminal(interfaceDecl.GetUpperBoundPos(), SyntaxNodeKind.UpperBoundToken)

        let superTypes = interfaceDecl.GetSuperTypes()
        for (i in 0..superTypes.size) {
            if (let Some(anno) <- superTypes[i]) {
                transType(anno)
                resetGlobalVariables(ret, innerCmts)
                if (let Some(base) <- anno.GetBase()) {
                    transBasicTerminal(base.GetBitAndPos(), SyntaxNodeKind.BitAndToken)
                }
            }
        }

        if (let Some(db) <- interfaceDecl.GetBase()) {
            if (let Some(generic) <- db.GetGeneric()) {
                let genericConstraints = generic.GetGenericConstraints();
                if (genericConstraints.size != 0) {
                    addChild(ret, transGenericConstraints(genericConstraints))
                }
                resetGlobalVariables(ret, innerCmts)
            }
        }

        if (let Some(body) <- interfaceDecl.GetBody()) {
            let declList = body.GetDecls()
            addChild(ret, transClassBody(body.GetBase(), declList, body.GetLeftCurlPos(), body.GetRightCurlPos()))
            resetGlobalVariables(ret, innerCmts)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.InterfaceDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transExtendDecl(extendDecl: SyntaxFormat_ExtendDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = extendDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- extendDecl.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)
            // extend
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.ExtendToken)

            if (let Some(generic) <- db.GetGeneric()) {
                let typeParameters = generic.GetTypeParameters()
                if (typeParameters.size != 0) {
                    addChild(ret,
                        transTypeArguments(typeParameters, generic.GetLeftAnglePos(), generic.GetRightAnglePos()))
                }
            }
            resetGlobalVariables(ret, innerCmts)
        }

        if (let Some(extendType) <- extendDecl.GetExtendedType()) {
            transType(extendType)
            resetGlobalVariables(ret, innerCmts)
        }

        transBasicTerminal(extendDecl.GetUpperBoundPos(), SyntaxNodeKind.UpperBoundToken)

        let superTypes = extendDecl.GetInterfaces()
        for (i in 0..superTypes.size) {
            if (let Some(anno) <- superTypes[i]) {
                transType(anno)
                resetGlobalVariables(ret, innerCmts)
                if (let Some(base) <- anno.GetBase()) {
                    transBasicTerminal(base.GetBitAndPos(), SyntaxNodeKind.BitAndToken)
                }
            }
        }

        if (let Some(db) <- extendDecl.GetBase()) {
            if (let Some(generic) <- db.GetGeneric()) {
                let genericConstraints = generic.GetGenericConstraints();
                if (genericConstraints.size != 0) {
                    addChild(ret, transGenericConstraints(genericConstraints))
                }
                resetGlobalVariables(ret, innerCmts)
            }
        }

        let memberDecls = extendDecl.GetMembers()
        addChild(ret, transClassBody(memberDecls, extendDecl.GetLeftCurlPos(), extendDecl.GetRightCurlPos()))
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ExtendDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transEnumBody(enumDecl: SyntaxFormat_EnumDecl, decls: Array<Option<SyntaxFormat_Decl>>,
        constructors: Array<Option<SyntaxFormat_Decl>>, lcurlPos: SyntaxFormat_Position, rcurlPos: SyntaxFormat_Position): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        let innerCmts = innerComments
        // add prefix whitespace and move cursor
        addWhitespaceAndMoveCursor(lcurlPos)
        curChildren = ret
        transBasicTerminal(lcurlPos, SyntaxNodeKind.LCurlToken)

        let constructorSize = constructors.size
        let bitOrTokenSize = enumDecl.GetBitOrPosVec().size
        var bitFirstFlag = false
        if (bitOrTokenSize > constructorSize || (bitOrTokenSize == constructorSize && !enumDecl.GetHasEllipsis())) {
            bitFirstFlag = true
        }

        let cons = getElements<SyntaxFormat_Decl>(constructors)
        for (i in 0..cons.size) {
            // | Enum | Enum2 | ...
            if (bitFirstFlag) {
                if (i < enumDecl.GetBitOrPosVec().size) {
                    transBasicTerminal(enumDecl.GetBitOrPosVec()[i], SyntaxNodeKind.BitOrToken)
                }
                addChild(ret, transEnumConstructor(cons[i]))
                innerComments = innerCmts
                curChildren = ret
            } else {
                // Enum | Enum2 | Enum3 | ...
                addChild(ret, transEnumConstructor(cons[i]))
                innerComments = innerCmts
                curChildren = ret
                if (i < enumDecl.GetBitOrPosVec().size) {
                    transBasicTerminal(enumDecl.GetBitOrPosVec()[i], SyntaxNodeKind.BitOrToken)
                }
            }
        }

        if (enumDecl.GetHasEllipsis()) {
            if (bitFirstFlag) {
                transBasicTerminal(enumDecl.GetBitOrPosVec()[bitOrTokenSize - 1], SyntaxNodeKind.BitOrToken)
            }
            transBasicTerminal(enumDecl.GetEllipsisPos(), SyntaxNodeKind.EllipsisToken)
        }

        for (decl in decls) {
            if (let Some(dl) <- decl) {
                addChild(ret, transDecl(dl))
                innerComments = innerCmts
                curChildren = ret
            }
        }

        transBasicTerminal(rcurlPos, SyntaxNodeKind.RCurlToken)
        builder.buildNonTerminal(SyntaxNodeKind.Body, ret.toArray())
    }

    private func transEnumDecl(enumDecl: SyntaxFormat_EnumDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = enumDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- enumDecl.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)
            // func
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.EnumToken)
            transDeclIdentifierAndTypeParams(db, ret, innerCmts)
        }

        transBasicTerminal(enumDecl.GetUpperBoundPos(), SyntaxNodeKind.UpperBoundToken)

        let superTypes = enumDecl.GetSuperInterfaceTypes()
        for (i in 0..superTypes.size) {
            if (let Some(anno) <- superTypes[i]) {
                transType(anno)
                resetGlobalVariables(ret, innerCmts)
                if (let Some(base) <- anno.GetBase()) {
                    transBasicTerminal(base.GetBitAndPos(), SyntaxNodeKind.BitAndToken)
                }
            }
        }

        if (let Some(db) <- enumDecl.GetBase()) {
            if (let Some(generic) <- db.GetGeneric()) {
                let genericConstraints = generic.GetGenericConstraints();
                if (genericConstraints.size != 0) {
                    addChild(ret, transGenericConstraints(genericConstraints))
                }
                resetGlobalVariables(ret, innerCmts)
            }
        }

        var memberDecls = enumDecl.GetMembers()
        var constructors = enumDecl.GetConstructors()
        addChild(ret,
            transEnumBody(enumDecl, memberDecls, constructors, enumDecl.GetLeftCurlPos(), enumDecl.GetRightCurlPos()))
        resetGlobalVariables(ret, innerCmts)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.EnumDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transEnumConstructor(enumConstructor: SyntaxFormat_Decl): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = enumConstructor.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts
        let astKind: String = nodeBase.getOrThrow().GetAstKind()
        if (astKind == "macro_expand_decl") {
            let table = enumConstructor.table
            let off: UInt32 = UInt32(table.offset(enumConstructor.DECL)) + table.pos
            return transMacroExpandDecl(SyntaxFormat_MacroExpandDecl(table.bytes, off), Array<SyntaxNodeImpl>(),
                isEnumConstructor: true)
        }
        if (let Some(db) <- enumConstructor.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)

            // identifier
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
        }

        if (let Some(funcDecl) <- enumConstructor.GetDeclAsFuncDecl() && let Some(body) <- funcDecl.GetFuncBody() && let Some(paramList) <- body
            .GetParamList()) {
            let bodyBase = body.GetBase()
            // EnumConstructor body has no innerComments
            let (leadBodyCmts, _, trailBodyCmts) = getCommentGroups(bodyBase)
            addLeadingComments(bodyBase, ret, leadBodyCmts)

            let paramBase = paramList.GetBase()
            // EnumConstructor paramList has no innerComments
            let (leadParamListCmts, _, trailParamListCmts) = getCommentGroups(paramBase)
            addLeadingComments(paramBase, ret, leadParamListCmts)
            transBasicTerminal(paramList.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

            let params = paramList.GetParams()
            for (param in getElements<SyntaxFormat_FuncParam>(params)) {
                let paramNodeBase = param.GetNodeBase()
                let (leadParamCmts, _, trailParamCmts) = getCommentGroups(paramNodeBase)
                trailComments = trailParamCmts
                // save leadingComments to temp ret, add to typeAnnotation node later
                addLeadingComments(paramNodeBase, leadCommentNodes, leadParamCmts)
                resetGlobalVariables(ret, innerCmts)
                // type
                if (let Some(vb) <- param.GetBase() && let Some(ty) <- vb.GetType()) {
                    transType(ty)
                    resetGlobalVariables(ret, innerCmts)
                }
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(param.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
            transBasicTerminal(paramList.GetRightParenPos(), SyntaxNodeKind.RParenToken)
            if (trailParamListCmts.size > 0) {
                addChild(ret, transCommentGroupList(trailParamListCmts))
                resetGlobalVariables(ret, innerCmts)
            }
            if (trailBodyCmts.size > 0) {
                addChild(ret, transCommentGroupList(trailBodyCmts))
                resetGlobalVariables(ret, innerCmts)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.EnumConstructor, ret.toArray())
    }

    private func transPropDecl(propDecl: SyntaxFormat_PropDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = propDecl.GetBase().getOrThrow().GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(varDecl) <- propDecl.GetBase() && let Some(db) <- varDecl.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)
            // prop
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.PropToken)
            // identifier
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
            transBasicTerminal(propDecl.GetColonPos(), SyntaxNodeKind.ColonToken)

            if (let Some(ty) <- varDecl.GetType()) {
                transType(ty)
                resetGlobalVariables(ret, innerCmts)
            }
            transBasicTerminal(propDecl.GetLeftCurlPos(), SyntaxNodeKind.LCurlToken)

            var getters = propDecl.GetGetters()
            if (getters.size != 0) {
                if (let Some(getter) <- getters[0]) {
                    addChild(ret, transFuncDecl(getter))
                    resetGlobalVariables(ret, innerCmts)
                }
            }
            var setters = propDecl.GetSetters()
            if (setters.size != 0) {
                if (let Some(setter) <- setters[0]) {
                    addChild(ret, transFuncDecl(setter))
                    resetGlobalVariables(ret, innerCmts)
                }
            }
            transBasicTerminal(propDecl.GetRightCurlPos(), SyntaxNodeKind.RCurlToken)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.PropDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transMacroDecl(macroDecl: SyntaxFormat_MacroDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()

        let nodeBase = macroDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- macroDecl.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)
            transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.MacroToken)
            // identifier
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
        }

        if (let Some(body) <- macroDecl.GetFuncBody()) {
            if (let Some(paramList) <- body.GetParamList()) {
                addChild(ret, transParamList(paramList))
                moveCursorToEnd(paramList.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)

            if (let Some(ty) <- body.GetRetType() && isValidPosition(body.GetColonPos())) {
                // :
                transBasicTerminal(body.GetColonPos(), SyntaxNodeKind.ColonToken)
                // type
                transType(ty)
            }
        }
        finishFuncBodyBlockAndComments(macroDecl.GetFuncBody(), ret, innerCmts, trailCmts)
        builder.buildNonTerminal(SyntaxNodeKind.MacroDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transTokenList(tokenArray: Array<Option<SyntaxFormat_Token>>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret
        for (tk in tokenArray) {
            if (let Some(v) <- tk) {
                transTokenTerminal(v.GetPos(), getTokenKind(v.GetKind()), v.GetValue(), needNewLine: true,
                    delimiterNum: v.GetDelimiterNum(), isSingleQuote: v.GetIsSingleQuote(), hasEscape: v.GetHasEscape())
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.TokenList, ret.toArray())
    }

    private func transSymbolRef4Invocation(invocation: SyntaxFormat_MacroInvocation): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret
        transIdentifier(invocation.GetIdentifierPos(), invocation.GetFullName())

        builder.buildNonTerminal(SyntaxNodeKind.RefExpr, ret.toArray())
    }

    private func transMacroInvocationCalleeAttrsAndParenArgs(invocation: SyntaxFormat_MacroInvocation,
        ret: ArrayList<SyntaxNodeImpl>, innerCmts: Array<Option<SyntaxFormat_CommentGroup>>): Bool {
        addChild(ret, transSymbolRef4Invocation(invocation))
        resetGlobalVariables(ret, innerCmts)

        transBasicTerminal(invocation.GetLeftSquarePos(), SyntaxNodeKind.LSquareToken)

        addChild(ret, transTokenList(invocation.GetAttrs()))
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(invocation.GetRightSquarePos(), SyntaxNodeKind.RSquareToken)

        if (invocation.GetHasParenthesis()) {
            transBasicTerminal(invocation.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

            addChild(ret, transTokenList(invocation.GetArgs()))
            resetGlobalVariables(ret, innerCmts)

            transBasicTerminal(invocation.GetRightParenPos(), SyntaxNodeKind.RParenToken)
            return true
        }
        return false
    }

    private func createArgumentTokens(invocation: SyntaxFormat_MacroInvocation) {
        var argTokens = Tokens()
        var position = invocation.GetAtPos()
        let atExcl = Token(TokenKind.AT_EXCL).addPosition(position.fileId, position.line, position.column)
        argTokens.append(atExcl)

        position = invocation.GetIdentifierPos()
        let identifier = Token(TokenKind.IDENTIFIER, invocation.GetIdentifier()).addPosition(position.fileId,
            position.line, position.column)
        argTokens.append(identifier)

        position = invocation.GetLeftSquarePos()
        let lSquare = Token(TokenKind.LSQUARE).addPosition(position.fileId, position.line, position.column)
        argTokens.append(lSquare)

        for (tk in invocation.GetAttrs()) {
            if (let Some(v) <- tk) {
                position = v.GetPos()
                argTokens.append(
                    Token(getTokenKind(v.GetKind()), v.GetValue()).addPosition(position.fileId, position.line,
                        position.column))
            }
        }

        position = invocation.GetRightSquarePos()
        let rSquare = Token(TokenKind.RSQUARE).addPosition(position.fileId, position.line, position.column)
        argTokens.append(rSquare)
        return argTokens
    }

    func createCustomAnnotation(invocation: SyntaxFormat_MacroInvocation): ?SyntaxFormat_Annotation {
        let argTokens = createArgumentTokens(invocation)
        let node = unsafe {
            try {
                parse(argTokens, {p: CPointer<UInt8> => return CJ_ParseAnnotationArguments(p)})
            } catch (e: Exception) {
                throw Exception("\n" + e.message + "parsing custom annotation error.")
            }
        }
        return node.GetRootAsAnnotation()
    }

    private func transDeclWithAtExclAnnotation(annos: Array<Option<SyntaxFormat_Annotation>>,
        invocation: SyntaxFormat_MacroInvocation, leadCmts: Array<Option<SyntaxFormat_CommentGroup>>,
        trailCmts: Array<Option<SyntaxFormat_CommentGroup>>, isEnumConstructor!: Bool = false): ?SyntaxNodeImpl {
        // BNF: (former annos)? atExcel decl
        let tmpInnerComments = innerComments
        // transAnnotationList
        var formerAnnos = transAnnotations(annos)
        innerComments = tmpInnerComments
        if (let Some(former) <- formerAnnos && let Some(formerAnno) <- (former as NonTerminal) && let Some(v) <- createCustomAnnotation(
            invocation)) {
            // transAtExcl and add to AnnotationList
            let ret = ArrayList<SyntaxNodeImpl>(formerAnno.children)
            if (ret.size > 0) {
                curChildren = ret
            }
            addChild(ret, transAnnotation(v))
            innerComments = tmpInnerComments
            formerAnnos = builder.buildNonTerminal(SyntaxNodeKind.AnnotationList, ret.toArray())
        }

        // store space and newLine before decl
        var retBefore = ArrayList<SyntaxNodeImpl>()
        curChildren = retBefore
        // transDecl
        // merge formerAnnos and atExcel and into decl
        let declNodeImpl: ?SyntaxNodeImpl = if (let Some(dl) <- invocation.GetDecl()) {
            if (isEnumConstructor) {
                transEnumConstructor(dl)
            } else {
                transDecl(dl)
            }
        } else {
            None
        }
        if (let Some(dl) <- declNodeImpl && let Some(nt) <- (dl as NonTerminal) && nt.children.size != 0) {
            var ret = ArrayList<SyntaxNodeImpl>(nt.children)
            if (let Some(annos) <- formerAnnos && let Some(formers) <- (annos as NonTerminal)) {
                if (ret[0].kind == SyntaxNodeKind.AnnotationList && let Some(annoList) <- (ret[0] as NonTerminal)) {
                    let firstChildRet = ArrayList<SyntaxNodeImpl>(annoList.children)
                    // already have a annoList, merge formerAnnotations init annoList
                    // add space and newLine first           
                    firstChildRet.add(all: retBefore, at: 0)
                    // add new annoList
                    firstChildRet.add(all: formers.children, at: 0)
                    ret[0] = builder.buildNonTerminal(SyntaxNodeKind.AnnotationList, firstChildRet.toArray())
                } else {
                    // not have a annoList, add formerAnnos to decl
                    // add space and newLine first
                    ret.add(all: retBefore, at: 0)
                    // add new annoList
                    ret.add(annos, at: 0)
                }
            }
            if (leadCmts.size > 0) {
                // add space and newLine first           
                ret.add(all: retBefore, at: 0)
                // add new annoList
                ret.add(transCommentGroupList(leadCmts).getOrThrow(), at: 0)
            }
            moveCursorToEnd(invocation.GetDecl().getOrThrow().GetBase().getOrThrow().GetBase())
            if (trailCmts.size > 0) {
                addChild(ret, transCommentGroupList(trailCmts))
            }
            return builder.buildNonTerminal(nt.kind, ret.toArray())
        }
        return None
    }

    private func transMacroExpandDecl(macroExpandDecl: SyntaxFormat_MacroExpandDecl, preChildren: Array<SyntaxNodeImpl>,
        isEnumConstructor!: Bool = false): ?SyntaxNodeImpl {
        let nodeBase = macroExpandDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        innerComments = innerCmts

        // if AtExcl, trans macro  to annotation
        if (let Some(db) <- macroExpandDecl.GetBase() && let Some(invocation) <- macroExpandDecl.GetInvocation() &&
            invocation.GetIsCompileTimeVisible()) {
            return transDeclWithAtExclAnnotation(db.GetAnnotations(), invocation, leadCmts, trailCmts,
                isEnumConstructor: isEnumConstructor)
        }

        var ret = ArrayList<SyntaxNodeImpl>()

        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(db) <- macroExpandDecl.GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)
        }

        if (let Some(invocation) <- macroExpandDecl.GetInvocation()) {
            transBasicTerminal(invocation.GetAtPos(), SyntaxNodeKind.AtToken)

            let hasParenthesizedArgs = transMacroInvocationCalleeAttrsAndParenArgs(invocation, ret, innerCmts)
            if (!hasParenthesizedArgs) {
                if (let Some(dl) <- invocation.GetDecl()) {
                    if (isEnumConstructor) {
                        addChild(ret, transEnumConstructor(dl))
                    } else {
                        addChild(ret, transDecl(dl))
                    }
                    resetGlobalVariables(ret, innerCmts)
                }
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MacroExpandDecl, ret.toArray(), preChildren: preChildren)
    }

    private func transMacroExpandParam(macroExpandParam: SyntaxFormat_MacroExpandParam): ?SyntaxNodeImpl {
        let nodeBase = macroExpandParam.GetBase().getOrThrow().GetNodeBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        innerComments = innerCmts

        // if AtExcl, trans macro  to annotation
        if (let Some(funcParam) <- macroExpandParam.GetBase() && let Some(varDecl) <- funcParam.GetBase() && let Some(db) <- varDecl
            .GetBase() && let Some(invocation) <- macroExpandParam.GetInvocation() &&
            invocation.GetIsCompileTimeVisible()) {
            return transDeclWithAtExclAnnotation(db.GetAnnotations(), invocation, leadCmts, trailCmts)
        }

        var ret = ArrayList<SyntaxNodeImpl>()

        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(funcParam) <- macroExpandParam.GetBase() && let Some(varDecl) <- funcParam.GetBase() && let Some(db) <- varDecl
            .GetBase()) {
            transDeclAnnotationsAndModifiers(db, ret, innerCmts)
        }

        if (let Some(invocation) <- macroExpandParam.GetInvocation()) {
            transBasicTerminal(invocation.GetAtPos(), SyntaxNodeKind.AtToken)
            resetGlobalVariables(ret, innerCmts)

            let hasParenthesizedArgs = transMacroInvocationCalleeAttrsAndParenArgs(invocation, ret, innerCmts)
            if (!hasParenthesizedArgs) {
                if (let Some(decl) <- invocation.GetDecl() && let Some(param) <- decl.GetDeclAsFuncParam()) {
                    addChild(ret, transFuncParam(param))
                    resetGlobalVariables(ret, innerCmts)
                }
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MacroExpandParam, ret.toArray())
    }

    private func transMacroExpandExpr(macroExpandExpr: SyntaxFormat_MacroExpandExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(macroExpandExpr.GetBase())
        var ret = ArrayList<SyntaxNodeImpl>()
        curChildren = ret

        let nodeBase = macroExpandExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(invocation) <- macroExpandExpr.GetInvocation()) {
            transBasicTerminal(invocation.GetAtPos(), SyntaxNodeKind.AtToken)
            resetGlobalVariables(ret, innerCmts)

            let hasParenthesizedArgs = transMacroInvocationCalleeAttrsAndParenArgs(invocation, ret, innerCmts)
            if (!hasParenthesizedArgs) {
                if (let Some(dl) <- invocation.GetDecl()) {
                    addChild(ret, transDecl(dl))
                    resetGlobalVariables(ret, innerCmts)
                }
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MacroExpandExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transGenericConstraint(constraint: SyntaxFormat_GenericConstraint): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = constraint.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(ty) <- constraint.GetType()) {
            if (let Some(tyBase) <- ty.GetBase()) {
                addWhitespaceAndMoveCursorToBegin(tyBase.GetBase())
                resetGlobalVariables(ret, innerCmts)
                addChild(ret, transRefType(ty))
                moveCursorToEnd(tyBase.GetBase())
            }
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(constraint.GetOperatorPos(), SyntaxNodeKind.UpperBoundToken)
        let upperBounds = constraint.GetUpperBound()
        let bitAndPos = constraint.GetBitAndPosVec()
        if (upperBounds.size != bitAndPos.size + 1) {
            return None
        }
        for (i in 0..upperBounds.size) {
            if (let Some(upperBound) <- upperBounds[i]) {
                transType(upperBound)
                resetGlobalVariables(ret, innerCmts)
                if (i < bitAndPos.size) {
                    transBasicTerminal(bitAndPos[i], SyntaxNodeKind.BitAndToken)
                }
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.GenericConstraint, ret.toArray())
    }

    private func transGenericConstraints(genericConstraints: Array<Option<SyntaxFormat_GenericConstraint>>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        var whereFlag = true
        for (genericConstraint in genericConstraints) {
            if (let Some(constraint) <- genericConstraint) {
                addWhitespaceAndMoveCursorToBegin(constraint.GetBase())
                if (whereFlag) {
                    curChildren = ret
                    ret.add(builder.buildBasicTerminal(SyntaxNodeKind.WhereToken))
                    moveCursorColumn(constraint.GetWherePos(), SyntaxNodeKind.WhereToken.toString().size)
                    whereFlag = false
                }
                addChild(ret, transGenericConstraint(constraint))
                curChildren = ret
                transBasicTerminal(constraint.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.GenericConstraints, ret.toArray())
    }

    private func transGenericParam(param: SyntaxFormat_GenericParamDecl): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(param.GetBase().getOrThrow().GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = param.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- param.GetBase()) {
            transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
        }
        resetGlobalVariables(ret, innerCmts)

        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.GenericParam, ret.toArray())
    }

    private func transTypeArguments(typeParameters: Array<Option<SyntaxFormat_GenericParamDecl>>,
        ltPos: SyntaxFormat_Position, gtPos: SyntaxFormat_Position): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        addWhitespace(ltPos)
        curChildren = ret

        transBasicTerminal(ltPos, SyntaxNodeKind.LtToken)
        for (typeParameter in typeParameters) {
            if (let Some(genericTy) <- typeParameter) {
                addChild(ret, transGenericParam(genericTy))
                curChildren = ret

                transBasicTerminal(genericTy.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
        }
        transBasicTerminal(gtPos, SyntaxNodeKind.GtToken)
        builder.buildNonTerminal(SyntaxNodeKind.TypeArguments, ret.toArray())
    }

    private func transTypeArguments(typeParameters: Array<Option<SyntaxFormat_Type>>, ltPos: SyntaxFormat_Position,
        gtPos: SyntaxFormat_Position): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        addWhitespace(ltPos)
        curChildren = ret
        transBasicTerminal(ltPos, SyntaxNodeKind.LtToken)
        for (typeParameter in typeParameters) {
            if (let Some(ty) <- typeParameter) {
                transType(ty)
                curChildren = ret
                if (let Some(tb) <- ty.GetBase()) {
                    transBasicTerminal(tb.GetCommaPos(), SyntaxNodeKind.CommaToken)
                }
            }
        }
        transBasicTerminal(gtPos, SyntaxNodeKind.GtToken)
        builder.buildNonTerminal(SyntaxNodeKind.TypeArguments, ret.toArray())
    }

    private func findStatic(modifiers: Array<Option<SyntaxFormat_Modifier>>): Bool {
        for (modifier in modifiers) {
            if (let Some(mod) <- modifier) {
                if (mod.GetKind() == 118) { //find static
                    return true
                }
            }
        }
        return false
    }

    func transFuncHeader(funcDecl: SyntaxFormat_FuncDecl, ret: ArrayList<SyntaxNodeImpl>, nodeKind: SyntaxNodeKind,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        var identifier = ""
        var modifiers = Array<Option<SyntaxFormat_Modifier>>()
        var kind = nodeKind

        if (let Some(db) <- funcDecl.GetBase()) {
            modifiers = db.GetModifiers()
            identifier = db.GetIdentifier()
            if (funcDecl.GetIsGetter() || funcDecl.GetIsSetter()) {
                kind = SyntaxNodeKind.PropGetterOrSetter
            } else if (identifier == "init" && findStatic(modifiers)) {
                kind = SyntaxNodeKind.StaticInit
            }
            // annotation
            if (db.GetAnnotations().size != 0) {
                addChild(ret, transAnnotations(db.GetAnnotations()))
            } else {
                // The begin of FuncDecl is not begin of annotations
                addWhitespaceAndMoveCursorToBegin(db.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)
            // modifier
            if (modifiers.size != 0) {
                addChild(ret, transModifiers(modifiers))
                resetGlobalVariables(ret, innerCmts)
            }
            if (funcDecl.GetIsGetter()) {
                transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.GetToken)
            } else if (funcDecl.GetIsSetter()) {
                transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.SetToken)
            } else {
                if (identifier == "init") {
                    transBasicTerminal(db.GetIdentifierPos(), SyntaxNodeKind.InitToken)
                } else if (identifier == "~init") {
                    // IdentifierPos ---- ~,  KeywordPos ---- init
                    transBasicTerminal(db.GetIdentifierPos(), SyntaxNodeKind.BitNotToken)
                    transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.InitToken)
                } else {
                    // func
                    transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.FuncToken)
                    // identifier
                    transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
                }
            }
        }
        return (ret, kind, identifier, modifiers)
    }

    func transFuncBody(funcDecl: SyntaxFormat_FuncDecl, nodes: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>, identifier: String,
        modifiers: Array<Option<SyntaxFormat_Modifier>>) {
        var ret: ArrayList<SyntaxNodeImpl> = nodes
        if (let Some(body) <- funcDecl.GetFuncBody()) {
            if (let Some(generic) <- body.GetGeneric()) {
                let typeParameters = generic.GetTypeParameters()
                if (typeParameters.size != 0) {
                    addChild(ret,
                        transTypeArguments(typeParameters, generic.GetLeftAnglePos(), generic.GetRightAnglePos()))
                }
            }
            resetGlobalVariables(ret, innerCmts)

            if (funcDecl.GetIsSetter() && let Some(paramList) <- body.GetParamList()) {
                transBasicTerminal(paramList.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
                let params = paramList.GetParams()
                if (params.size > 0 && let Some(param) <- params[0] && let Some(vb) <- param.GetBase() && let Some(db) <- vb
                    .GetBase()) {
                    let paramNodeBase = param.GetNodeBase()
                    // Setter has no innerComments
                    let (leadParamListCmts, _, trailParamListCmts) = getCommentGroups(paramNodeBase)
                    addLeadingComments(paramNodeBase, ret, leadParamListCmts)
                    transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())

                    addChild(ret, transCommentGroupList(trailParamListCmts))
                    resetGlobalVariables(ret, innerCmts)
                }
                transBasicTerminal(paramList.GetRightParenPos(), SyntaxNodeKind.RParenToken)
            } else if (funcDecl.GetIsGetter() || (identifier == "init" && findStatic(modifiers))) {
                if (let Some(paramList) <- body.GetParamList()) {
                    let paramListBase = paramList.GetBase()
                    // Getter or Init has no leadingComments and trailingComments
                    let (_, innerParamListCmts, _) = getCommentGroups(paramListBase)
                    innerComments = innerParamListCmts
                    transBasicTerminal(paramList.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
                    transBasicTerminal(paramList.GetRightParenPos(), SyntaxNodeKind.RParenToken)
                    innerComments = innerCmts
                }
            } else if (let Some(paramList) <- body.GetParamList()) {
                addChild(ret, transParamList(paramList))
                moveCursorToEnd(paramList.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)
            if (let Some(ty) <- body.GetRetType()) {
                // :
                transBasicTerminal(body.GetColonPos(), SyntaxNodeKind.ColonToken)
                // type
                transType(ty)
                resetGlobalVariables(ret, innerCmts)
            }
            if (let Some(generic) <- body.GetGeneric()) {
                let genericConstraints = generic.GetGenericConstraints();
                if (genericConstraints.size != 0) {
                    addChild(ret, transGenericConstraints(genericConstraints))
                }
                resetGlobalVariables(ret, innerCmts)
            }
            // block
            if (let Some(block) <- body.GetBody()) {
                addChild(ret, transBlock(block))
            }
        }
        return ret
    }

    private func transFuncDecl(funcDecl: SyntaxFormat_FuncDecl, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var ret = ArrayList<SyntaxNodeImpl>()
        var kind = SyntaxNodeKind.FuncDecl
        var identifier = ""
        var modifiers = Array<Option<SyntaxFormat_Modifier>>()

        let nodeBase = funcDecl.GetBase().getOrThrow().GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        (ret, kind, identifier, modifiers) = transFuncHeader(funcDecl, ret, kind, innerCmts)

        ret = transFuncBody(funcDecl, ret, innerCmts, identifier, modifiers)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(kind, ret.toArray(), preChildren: preChildren)
    }

    // functionParameters
    // MacroExpandParam CommaToken manually added
    private func transParamList(paramList: SyntaxFormat_FuncParamList, isLambda!: Bool = false): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(paramList.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = paramList.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(paramList.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        let params = getElements<SyntaxFormat_FuncParam>(paramList.GetParams())
        for (i in 0..params.size) {
            let param = params[i]
            addWhitespaceAndMoveCursorToBegin(param.GetNodeBase())
            if (let Some(macroExpandParam) <- param.GetMacroParamAsMacroExpandParam()) {
                addChild(ret, transMacroExpandParam(macroExpandParam))
                resetGlobalVariables(ret, innerCmts)
                if (i < params.size - 1) {
                    addChild(ret, builder.buildBasicTerminal(SyntaxNodeKind.CommaToken))
                }
                moveCursorColumn(col: Int32(SyntaxNodeKind.CommaToken.toString().size))
            } else if (isLambda) {
                addChild(ret, transLambdaParam(param))
                resetGlobalVariables(ret, innerCmts)
                if (isValidPosition(param.GetCommaPos())) {
                    transBasicTerminal(param.GetCommaPos(), SyntaxNodeKind.CommaToken)
                }
            } else {
                addChild(ret, transFuncParam(param))
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(param.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
        }
        transBasicTerminal(paramList.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ParameterList, ret.toArray())
    }

    private func transLambdaParam(param: SyntaxFormat_FuncParam): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = param.GetNodeBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(vb) <- param.GetBase()) {
            resetGlobalVariables(ret, innerCmts)
            if (let Some(db) <- vb.GetBase()) {
                // The begin of FuncDecl is not begin of annotations
                addWhitespaceAndMoveCursorToBegin(db.GetBase())
                resetGlobalVariables(ret, innerCmts)
                transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
            }
            if (isValidPosition(param.GetColonPos())) {
                transBasicTerminal(param.GetColonPos(), SyntaxNodeKind.ColonToken)
            }
            if (let Some(ty) <- vb.GetType()) {
                transType(ty)
                resetGlobalVariables(ret, innerCmts)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.LambdaParam, ret.toArray())
    }

    private func transFuncParam(param: SyntaxFormat_FuncParam, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = param.GetNodeBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts, isDecl: true)
        innerComments = innerCmts

        if (let Some(vb) <- param.GetBase()) {
            if (let Some(db) <- vb.GetBase()) {
                transDeclAnnotationsAndModifiers(db, ret, innerCmts)
                if (param.GetHasLetOrVar() && vb.GetIsVar()) {
                    transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.VarToken)
                } else if (param.GetHasLetOrVar()) {
                    transBasicTerminal(db.GetKeywordPos(), SyntaxNodeKind.LetToken)
                }
                transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
            }
            transBasicTerminal(param.GetNotMarkPos(), SyntaxNodeKind.NotToken)

            transBasicTerminal(param.GetColonPos(), SyntaxNodeKind.ColonToken)

            // type
            if (let Some(ty) <- vb.GetType()) {
                transType(ty)
                resetGlobalVariables(ret, innerCmts)
            }
            resetGlobalVariables(ret, innerCmts)

            if (let Some(expr) <- param.GetAssignment()) {
                transBasicTerminal(vb.GetAssignPos(), SyntaxNodeKind.AssignToken)
                transNoTerminalExpr(expr)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.FuncParam, ret.toArray(), preChildren: preChildren)
    }

    private func transBlock(block: SyntaxFormat_Block, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(block.GetBase())
        if (block.GetIsUnsafe() && isValidPosition(block.GetUnsafePos())) {
            transUnsafeExpr(block, preChildren)
        } else {
            transSafeBlock(block, preChildren)
        }
    }

    private func transSafeBlock(block: SyntaxFormat_Block, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = block.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        addWhitespaceAndMoveCursor(block.GetLeftCurlPos())
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(block.GetLeftCurlPos(), SyntaxNodeKind.LCurlToken)
        for (e in block.GetBody()) {
            if (let Some(expr) <- e) {
                resetGlobalVariables(ret, innerCmts)
                addChild(ret, transRoot(expr))
            }
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(block.GetRightCurlPos(), SyntaxNodeKind.RCurlToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.Block, ret.toArray(), preChildren: preChildren)
    }

    private func transUnsafeExpr(block: SyntaxFormat_Block, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = block.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(block.GetUnsafePos(), SyntaxNodeKind.UnsafeToken)

        addChild(ret, transSafeBlock(block))
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.UnsafeExpr, ret.toArray(), preChildren: preChildren)
    }

    // Expr
    private func transExpr(expr: SyntaxFormat_Expr, preChildren: Array<SyntaxNodeImpl>, isInterpol!: Bool = false): ?SyntaxNodeImpl {
        let table = expr.table
        let o: UInt16 = table.offset(expr.EXPR)
        let off: UInt32 = UInt32(o) + table.pos
        match (expr.GetExprType()) {
            case SyntaxFormat_AnyExpr.AnyExpr_CALL_EXPR => transCallExpr(SyntaxFormat_CallExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_UNARY_EXPR => transUnaryExpr(SyntaxFormat_UnaryExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_BINARY_EXPR => transBinaryExpr(SyntaxFormat_BinaryExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_LIT_CONST_EXPR => transLitConst(SyntaxFormat_LitConstExpr(table.bytes, off),
                preChildren, isInterpol: isInterpol)
            case SyntaxFormat_AnyExpr.AnyExpr_REF_EXPR => transRefExpr(SyntaxFormat_RefExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_ARRAY_LIT => transArrayLit(SyntaxFormat_ArrayLit(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_TUPLE_LIT => transTupleLit(SyntaxFormat_TupleLit(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_ARRAY_EXPR => transArrayExpr(SyntaxFormat_ArrayExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_RANGE_EXPR => transRangeExpr(SyntaxFormat_RangeExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_INC_OR_DEC_EXPR => transIncOrDecExpr(
                SyntaxFormat_IncOrDecExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_PAREN_EXPR => transParenExpr(SyntaxFormat_ParenExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_IS_EXPR => transIsExpr(SyntaxFormat_IsExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_AS_EXPR => transAsExpr(SyntaxFormat_AsExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_TYPE_CONV_EXPR => transTypeConvExpr(
                SyntaxFormat_TypeConvExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_OPTIONAL_EXPR => transOptionalExpr(SyntaxFormat_OptionalExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_OPTIONAL_CHAIN_EXPR => transOptionalChainExpr(
                SyntaxFormat_OptionalChainExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_ASSIGN_EXPR => transAssignExpr(SyntaxFormat_AssignExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_RETURN_EXPR => transReturnExpr(SyntaxFormat_ReturnExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_JUMP_EXPR => transJumpExpr(SyntaxFormat_JumpExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_MEMBER_ACCESS => transMemberAccess(SyntaxFormat_MemberAccess(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_SUBSCRIPT_EXPR => transSubscriptExpr(
                SyntaxFormat_SubscriptExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_LAMBDA_EXPR => transLambda(SyntaxFormat_LambdaExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_SYNCHRONIZED_EXPR => transSynchronizedExpr(
                SyntaxFormat_SynchronizedExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_SPAWN_EXPR => transSpawnExpr(SyntaxFormat_SpawnExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_IF_EXPR => transIfExpr(SyntaxFormat_IfExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_BLOCK => transBlock(SyntaxFormat_Block(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_WHILE_EXPR => transWhileExpr(SyntaxFormat_WhileExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_DO_WHILE_EXPR => transDoWhileExpr(SyntaxFormat_DoWhileExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_FOR_IN_EXPR => transForInExpr(SyntaxFormat_ForInExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_WILDCARD_EXPR => transWildcardExpr(SyntaxFormat_WildcardExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_MATCH_EXPR => transMatchExpr(SyntaxFormat_MatchExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_TRY_EXPR => transTryExpr(SyntaxFormat_TryExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_THROW_EXPR => transThrowExpr(SyntaxFormat_ThrowExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_INTERPOLATION_EXPR => transInterpolationExpr(
                SyntaxFormat_InterpolationExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_QUOTE_EXPR => transQuoteExpr(SyntaxFormat_QuoteExpr(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_TOKEN_PART => transQuoteTokenExpr(SyntaxFormat_TokenPart(table.bytes, off),
                preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_LET_PATTERN_DESTRUCTOR => transLetPattern(
                SyntaxFormat_LetPatternDestructor(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_TRAILING_CLOSURE_EXPR => transTrailingClosureExpr(
                SyntaxFormat_TrailingClosureExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_MACRO_EXPAND_EXPR => transMacroExpandExpr(
                SyntaxFormat_MacroExpandExpr(table.bytes, off), preChildren)
            case SyntaxFormat_AnyExpr.AnyExpr_PRIMITIVE_TYPE_EXPR => transPrimitiveTypeExpr(
                SyntaxFormat_PrimitiveTypeExpr(table.bytes, off))
            case _ => throw Exception("ParseException: The current version does not support this node.")
        }
    }

    private func transWildcardExpr(matchExpr: SyntaxFormat_WildcardExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        // justify: WildcardExpr -> WildcardPattern
        addWhitespaceAndMoveCursorToBegin(matchExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = matchExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- matchExpr.GetBase()) {
            resetGlobalVariables(ret, innerCmts)
            transBasicTerminal(db.GetBegin(), SyntaxNodeKind.WildcardToken)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.WildcardPattern, ret.toArray(), preChildren: preChildren)
    }

    private func transMatchExpr(matchExpr: SyntaxFormat_MatchExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(matchExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = matchExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- matchExpr.GetBase()) {
            resetGlobalVariables(ret, innerCmts)
            // match
            transBasicTerminal(db.GetBegin(), SyntaxNodeKind.MatchToken)

            // expr
            if (let Some(selector) <- matchExpr.GetSelector()) {
                // case 1: match (expr) { patterns }
                transBasicTerminal(matchExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
                addChild(ret, transExpr(selector))
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(matchExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
                transBasicTerminal(matchExpr.GetLeftCurlPos(), SyntaxNodeKind.LCurlToken)
                // match cases
                for (normalCase in getElements<SyntaxFormat_MatchCase>(matchExpr.GetMatchCases())) {
                    addChild(ret, transMatchCase(normalCase))
                    resetGlobalVariables(ret, innerCmts)
                }
                transBasicTerminal(matchExpr.GetRightCurlPos(), SyntaxNodeKind.RCurlToken)
            } else {
                // case 2: match { patterns }
                transBasicTerminal(matchExpr.GetLeftCurlPos(), SyntaxNodeKind.LCurlToken)
                // match cases
                for (otherCase in getElements<SyntaxFormat_MatchCaseOther>(matchExpr.GetMatchCaseOthers())) {
                    addChild(ret, transMatchCaseOther(otherCase))
                    resetGlobalVariables(ret, innerCmts)
                }
                transBasicTerminal(matchExpr.GetRightCurlPos(), SyntaxNodeKind.RCurlToken)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MatchExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transTryExpr(tryExpr: SyntaxFormat_TryExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(tryExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)

        let nodeBase = tryExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- tryExpr.GetBase()) {
            resetGlobalVariables(ret, innerCmts)
            // try
            transBasicTerminal(db.GetBegin(), SyntaxNodeKind.TryToken)
            // resourceSpec
            let (children, commaPos) = (tryExpr.GetResourceSpec(), tryExpr.GetResourceSpecCommaPosVec())

            transBasicTerminal(tryExpr.GetResourceSpecLparenPos(), SyntaxNodeKind.LParenToken)
            for (i in 0..children.size) {
                if (let Some(varDecl) <- children[i]) {
                    addChild(ret, transVarDecl(varDecl))
                    resetGlobalVariables(ret, innerCmts)
                }
                if (i < commaPos.size) {
                    transBasicTerminal(commaPos[i], SyntaxNodeKind.CommaToken)
                }
            }
            transBasicTerminal(tryExpr.GetResourceSpecRparenPos(), SyntaxNodeKind.RParenToken)

            // tryBlock
            if (let Some(block) <- tryExpr.GetTryBlock()) {
                addChild(ret, transBlock(block))
                resetGlobalVariables(ret, innerCmts)
            }

            // catch
            let (catchPos, lParenPos, rParenPos) = (tryExpr.GetCatchPosVec(), tryExpr.GetCatchLeftParenPosVec(),
                tryExpr.GetCatchRightParenPosVec())
            let (catchPatterns, catchBlocks) = (tryExpr.GetCatchPatterns(), tryExpr.GetCatchBlocks())
            for (i in 0..catchPos.size) {
                transBasicTerminal(catchPos[i], SyntaxNodeKind.CatchToken)
                transBasicTerminal(lParenPos[i], SyntaxNodeKind.LParenToken)
                if (let Some(pattern) <- catchPatterns[i]) {
                    addChild(ret, transCatchPattern(pattern))
                    resetGlobalVariables(ret, innerCmts)
                }
                transBasicTerminal(rParenPos[i], SyntaxNodeKind.RParenToken)
                if (let Some(block) <- catchBlocks[i]) {
                    addChild(ret, transBlock(block))
                    resetGlobalVariables(ret, innerCmts)
                }
            }
            // finally
            transBasicTerminal(tryExpr.GetFinallyPos(), SyntaxNodeKind.FinallyToken)
            if (let Some(block) <- tryExpr.GetFinallyBlock()) {
                addChild(ret, transBlock(block))
                resetGlobalVariables(ret, innerCmts)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TryExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transPattern(pattern: SyntaxFormat_Pattern): ?SyntaxNodeImpl {
        let table = pattern.table
        let o: UInt16 = table.offset(pattern.PATTERN)
        let off: UInt32 = UInt32(o) + table.pos
        match (pattern.GetPatternType()) {
            case AnyPattern_CONST_PATTERN => transConstPattern(SyntaxFormat_ConstPattern(table.bytes, off))
            case AnyPattern_WILDCARD_PATTERN => transWildcardPattern(SyntaxFormat_WildcardPattern(table.bytes, off))
            case AnyPattern_VAR_PATTERN => transVarBindingPattern(SyntaxFormat_VarPattern(table.bytes, off))
            case AnyPattern_TYPE_PATTERN => transTypePattern(SyntaxFormat_TypePattern(table.bytes, off))
            case AnyPattern_ENUM_PATTERN => transEnumPattern(SyntaxFormat_EnumPattern(table.bytes, off))
            case AnyPattern_VAR_OR_ENUM_PATTERN => transVarOrEnumPattern(SyntaxFormat_VarOrEnumPattern(table.bytes, off))
            case AnyPattern_TUPLE_PATTERN => transTuplePattern(SyntaxFormat_TuplePattern(table.bytes, off))
            case AnyPattern_EXCEPT_TYPE_PATTERN => transExceptTypePattern(SyntaxFormat_ExceptTypePattern(table.bytes, off))
            case _ => None
        }
    }

    private func transConstPattern(constPattern: SyntaxFormat_ConstPattern): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(constPattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = constPattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        // literal
        if (let Some(literal) <- constPattern.GetLiteral()) {
            addChild(ret, transExpr(literal))
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ConstPattern, ret.toArray())
    }

    private func transWildcardPattern(wildcard: SyntaxFormat_WildcardPattern): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(wildcard.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = wildcard.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- wildcard.GetBase()) {
            transBasicTerminal(db.GetBegin(), SyntaxNodeKind.WildcardToken)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.WildcardPattern, ret.toArray())
    }

    private func transVarBindingPattern(varPattern: SyntaxFormat_VarPattern): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(varPattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = varPattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(varDecl) <- varPattern.GetVarDecl()) {
            if (let Some(db) <- varDecl.GetBase()) {
                transIdentifier(db.GetIdentifierPos(), db.GetIdentifier())
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.VarBindingPattern, ret.toArray())
    }

    private func transVarOrEnumPattern(varOrEnumPattern: SyntaxFormat_VarOrEnumPattern): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(varOrEnumPattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = varOrEnumPattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- varOrEnumPattern.GetBase()) {
            transIdentifier(db.GetBegin(), varOrEnumPattern.GetIdentifier())
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.VarOrEnumPattern, ret.toArray())
    }

    private func transTypePattern(typePattern: SyntaxFormat_TypePattern): ?SyntaxNodeImpl {
        // (wildcardPattern | varBindingPattern) NL* COLON NL* type
        addWhitespaceAndMoveCursorToBegin(typePattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = typePattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        // (wildcardPattern | varBindingPattern)
        if (let Some(pat) <- typePattern.GetPattern()) {
            addChild(ret, transPattern(pat))
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(typePattern.GetColonPos(), SyntaxNodeKind.ColonToken)
        // type
        if (let Some(ty) <- typePattern.GetType()) {
            resetGlobalVariables(ret, innerCmts)
            transType(ty)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TypePattern, ret.toArray())
    }

    private func transCompositeType(mem: SyntaxFormat_MemberAccess): ?SyntaxNodeImpl {
        // (identifier NL* DOT NL*)* identifier ( NL* typeArguments)?
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = mem.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        // work stack
        let stack = ArrayStack<SyntaxFormat_MemberAccess>()
        stack.add(mem)
        var tmpMem = mem
        while (let Some(base) <- tmpMem.GetBaseExpr() && let Some(baseMem) <- base.GetExprAsMemberAccess()) {
            stack.add(baseMem)
            tmpMem = baseMem
        }
        // work stack is top: [A.B, B.C, C.D<Int64>] bottom
        while (let Some(curMem) <- stack.remove()) {
            // A<Int64>.B
            if (let Some(base) <- curMem.GetBaseExpr()) {
                if (let Some(baseRef) <- base.GetExprAsRefExpr()) {
                    if (let Some(ref) <- baseRef.GetRef()) {
                        transIdentifier(ref.GetIdentifierPos(), ref.GetIdentifier())
                    }
                    let typeArguments = baseRef.GetTypeArguments()
                    if (typeArguments.size > 0) {
                        addChild(ret,
                            transTypeArguments(typeArguments, baseRef.GetLeftAnglePos(), baseRef.GetRightAnglePos()))
                    }
                } else if (let Some(baseMem) <- base.GetExprAsMemberAccess()) {
                    transIdentifier(baseMem.GetFieldPos(), baseMem.GetField())
                    // P.A<Int64>.B
                    let typeArguments = baseMem.GetTypeArguments()
                    if (typeArguments.size > 0) {
                        addChild(ret,
                            transTypeArguments(typeArguments, baseMem.GetLeftAnglePos(), baseMem.GetRightAnglePos()))
                    }
                }
            }
            resetGlobalVariables(ret, innerCmts)
            if (!stack.isEmpty()) {
                transBasicTerminal(curMem.GetDotPos(), SyntaxNodeKind.DotToken)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.CompositeType, ret.toArray())
    }

    private func transEnumPattern(enumPattern: SyntaxFormat_EnumPattern): ?SyntaxNodeImpl {
        // (compositeType NL* DOT NL*)? identifier NL* enumPatternParameters?
        // enumPatternParameters : LPAREN NL* pattern (NL* COMMA NL* pattern)* NL* RPAREN
        addWhitespaceAndMoveCursorToBegin(enumPattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = enumPattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        // For example: pkg1.subpkg0.E<Int64>.C0
        // compositeType pkg1.subpkg0.E<Int64>
        // SymbolRef C0
        if (let Some(expr) <- enumPattern.GetRef()) {
            if (let Some(memAccess) <- expr.GetExprAsMemberAccess()) {
                addChild(ret, transCompositeType(memAccess))
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(memAccess.GetDotPos(), SyntaxNodeKind.DotToken)
                addChild(ret, transSymbolRef4MemberAccess(memAccess))
                resetGlobalVariables(ret, innerCmts)
            } else if (let Some(refExpr) <- expr.GetExprAsRefExpr()) {
                addChild(ret, transRefExpr(refExpr))
                resetGlobalVariables(ret, innerCmts)
            }
        }
        // patterns
        let patterns = enumPattern.GetPatterns()
        if (patterns.size > 0) {
            let commaPos = enumPattern.GetCommaPosVec()
            // RPAREN
            transBasicTerminal(enumPattern.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
            for (i in 0..patterns.size) {
                if (i > 0) {
                    transBasicTerminal(commaPos[i - 1], SyntaxNodeKind.CommaToken)
                }
                if (let Some(pat) <- patterns[i]) {
                    addChild(ret, transPattern(pat))
                }
                resetGlobalVariables(ret, innerCmts)
            }
            // RPAREN
            transBasicTerminal(enumPattern.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.EnumPattern, ret.toArray())
    }

    private func transTuplePattern(tuplePattern: SyntaxFormat_TuplePattern): ?SyntaxNodeImpl {
        // LPAREN NL* pattern (NL* COMMA NL* pattern)+ NL* RPAREN
        addWhitespaceAndMoveCursorToBegin(tuplePattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = tuplePattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(tuplePattern.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        // patterns
        let commaPos = tuplePattern.GetCommaPosVec()
        let patterns = tuplePattern.GetPatterns()
        for (i in 0..patterns.size) {
            if (i > 0) {
                transBasicTerminal(commaPos[i - 1], SyntaxNodeKind.CommaToken)
            }
            if (let Some(pat) <- patterns[i]) {
                addChild(ret, transPattern(pat))
            }
            resetGlobalVariables(ret, innerCmts)
        }
        // RPAREN
        transBasicTerminal(tuplePattern.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TuplePattern, ret.toArray())
    }

    private func transExceptTypePattern(exceptTypePattern: SyntaxFormat_ExceptTypePattern): ?SyntaxNodeImpl {
        let tmpChildren = curChildren
        if (let Some(pattern) <- exceptTypePattern.GetPattern()) {
            addChild(tmpChildren, transPattern(pattern))
            curChildren = tmpChildren
        }
        transBasicTerminal(exceptTypePattern.GetColonPos(), SyntaxNodeKind.ColonToken)

        let types = exceptTypePattern.GetTypes()
        let bitOrPoses = exceptTypePattern.GetBitOrPosVec()
        let types_ = getElements<SyntaxFormat_Type>(types)
        for (i in 0..types_.size) {
            transType(types_[i])
            curChildren = tmpChildren
            if (i < bitOrPoses.size) {
                transBasicTerminal(bitOrPoses[i], SyntaxNodeKind.BitOrToken)
            }
        }
        curChildren = tmpChildren
        return None
    }

    private func transCatchPattern(pattern: SyntaxFormat_Pattern): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(pattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = pattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        match (pattern.GetPatternType()) {
            case AnyPattern_WILDCARD_PATTERN => addChild(ret, transPattern(pattern))
            case AnyPattern_EXCEPT_TYPE_PATTERN => transPattern(pattern)
            case _ => return None
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.CatchPattern, ret.toArray())
    }

    private func transMatchCaseBody(body: SyntaxFormat_Block): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = body.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, leadCommentNodes, leadCmts)
        curChildren = ret
        innerComments = innerCmts

        for (exprOrDecl in body.GetBody()) {
            if (let Some(node) <- exprOrDecl) {
                addChild(ret, transRoot(node))
            }
            resetGlobalVariables(ret, innerCmts)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MatchCaseBody, ret.toArray())
    }

    private func prepareMatchCasePrefix(base: Option<SyntaxFormat_NodeBase>) {
        addWhitespaceAndMoveCursorToBegin(base)
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = base
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- base) {
            transBasicTerminal(db.GetBegin(), SyntaxNodeKind.CaseToken)
        }
        return (ret, innerCmts, trailCmts)
    }

    private func appendMatchCaseArrowAndBody(base: Option<SyntaxFormat_NodeBase>, arrowPos: SyntaxFormat_Position,
        body: Option<SyntaxFormat_Block>, ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        if (let Some(_) <- base) {
            resetGlobalVariables(ret, innerCmts)
            transBasicTerminal(arrowPos, SyntaxNodeKind.DoubleArrowToken)
            if (let Some(block) <- body) {
                addChild(ret, transMatchCaseBody(block))
            }
        }
    }

    private func transMatchCase(matchCase: SyntaxFormat_MatchCase): ?SyntaxNodeImpl {
        // CASE NL* pattern (NL* BITOR NL* pattern)* NL* (WHERE NL* expression)? NL* DOUBLE_ARROW NL* expressionOrDeclaration (end+ expressionOrDeclaration?)*
        let (ret, innerCmts, trailCmts) = prepareMatchCasePrefix(matchCase.GetBase())

        if (let Some(db) <- matchCase.GetBase()) {
            let bitOrPos = matchCase.GetBitOrPosVec()
            let patterns = matchCase.GetPatterns()
            for (i in 0..patterns.size) {
                if (i > 0) {
                    transBasicTerminal(bitOrPos[i - 1], SyntaxNodeKind.BitOrToken)
                }
                if (let Some(pattern) <- patterns[i]) {
                    addChild(ret, transPattern(pattern))
                }
                resetGlobalVariables(ret, innerCmts)
            }
            // patternGuard
            if (let Some(patGuard) <- matchCase.GetPatternguard()) {
                transBasicTerminal(matchCase.GetIfPos(), SyntaxNodeKind.WhereToken)
                addChild(ret, transExpr(patGuard))
            }
        }
        appendMatchCaseArrowAndBody(matchCase.GetBase(), matchCase.GetArrowPos(), matchCase.GetExprOrDecls(), ret, innerCmts)
        appendTrailingComments(ret, innerCmts, trailCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MatchCase, ret.toArray())
    }

    private func transMatchCaseOther(matchCase: SyntaxFormat_MatchCaseOther): ?SyntaxNodeImpl {
        // CASE NL* expression NL* DOUBLE_ARROW NL* expressionOrDeclaration (end+ expressionOrDeclaration?)*
        let (ret, innerCmts, trailCmts) = prepareMatchCasePrefix(matchCase.GetBase())

        if (let Some(db) <- matchCase.GetBase()) {
            if (let Some(caseExpr) <- matchCase.GetMatchExpr()) {
                addChild(ret, transExpr(caseExpr))
            }
        }
        appendMatchCaseArrowAndBody(matchCase.GetBase(), matchCase.GetArrowPos(), matchCase.GetExprOrDecls(), ret, innerCmts)
        appendTrailingComments(ret, innerCmts, trailCmts)
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MatchCase, ret.toArray())
    }

    private func transRefExpr(refExpr: SyntaxFormat_RefExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        if (refExpr.GetIsQuoteDollar()) {
            moveCursorColumn()
        } else {
            addWhitespaceAndMoveCursorToBegin(refExpr.GetBase())
        }
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = refExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(ref) <- refExpr.GetRef()) {
            match (ref.GetIdentifier()) {
                case "this" => ret.add(builder.buildBasicTerminal(SyntaxNodeKind.ThisToken))
                case "super" => ret.add(builder.buildBasicTerminal(SyntaxNodeKind.SuperToken))
                case _ => ret.add(builder.buildValuedTerminal(SyntaxNodeKind.IdentToken, ref.GetIdentifier()))
            }
            moveCursorColumn(ref.GetIdentifierPos(), ref.GetIdentifier().size)
        }
        let typeArguments = refExpr.GetTypeArguments()
        if (typeArguments.size != 0) {
            addChild(ret,
                transTypeArguments(typeArguments, refExpr.GetLeftAnglePos(), refExpr.GetRightAnglePos()).getOrThrow())
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.RefExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transArrayLit(arrayLit: SyntaxFormat_ArrayLit, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(arrayLit.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = arrayLit.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(arrayLit.GetLeftCurlPos(), SyntaxNodeKind.LSquareToken)

        let children = arrayLit.GetChildren()
        let commaPos = arrayLit.GetCommaPosVec()
        for (i in 0..children.size) {
            if (let Some(expr) <- children[i]) {
                transNoTerminalExpr(expr)
                resetGlobalVariables(ret, innerCmts)
            }
            if (i < commaPos.size) {
                transBasicTerminal(commaPos[i], SyntaxNodeKind.CommaToken)
            }
        }
        transBasicTerminal(arrayLit.GetRightCurlPos(), SyntaxNodeKind.RSquareToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ArrayLiteral, ret.toArray(), preChildren: preChildren)
    }

    private func transTupleLit(tupleLit: SyntaxFormat_TupleLit, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(tupleLit.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = tupleLit.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(tupleLit.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

        let children = tupleLit.GetChildren()
        let commaPos = tupleLit.GetCommaPosVec()
        for (i in 0..commaPos.size) {
            if (let Some(expr) <- children[i]) {
                transNoTerminalExpr(expr)
                resetGlobalVariables(ret, innerCmts)
            }
            transBasicTerminal(commaPos[i], SyntaxNodeKind.CommaToken)
        }
        if (let Some(expr) <- children[commaPos.size]) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }

        transBasicTerminal(tupleLit.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TupleLiteral, ret.toArray(), preChildren: preChildren)
    }

    private func transArrayExpr(arrayExpr: SyntaxFormat_ArrayExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(arrayExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = arrayExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(tp) <- arrayExpr.GetType()) {
            transType(tp)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(arrayExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

        for (p in arrayExpr.GetArgs()) {
            if (let Some(arg) <- p) {
                addWhitespaceAndMoveCursorToBegin(arg.GetBase())
                addChild(ret, transFuncArg(arg))
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(arg.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
        }

        transBasicTerminal(arrayExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.VArrayExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transRangeExpr(rangeExpr: SyntaxFormat_RangeExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(rangeExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = rangeExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(start) <- rangeExpr.GetStartExpr()) {
            transNoTerminalExpr(start)
        }
        resetGlobalVariables(ret, innerCmts)

        var kind = SyntaxNodeKind.RangeOpToken
        if (rangeExpr.GetIsClosed()) {
            kind = SyntaxNodeKind.ClosedRangeOpToken
        }
        transBasicTerminal(rangeExpr.GetRangePos(), kind)

        if (let Some(stop) <- rangeExpr.GetStopExpr()) {
            transNoTerminalExpr(stop)
        }
        resetGlobalVariables(ret, innerCmts)

        if (let Some(step) <- rangeExpr.GetStepExpr()) {
            transBasicTerminal(rangeExpr.GetColonPos(), SyntaxNodeKind.ColonToken)
            transNoTerminalExpr(step)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.RangeExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transIncOrDecExpr(incOrDecExpr: SyntaxFormat_IncOrDecExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(incOrDecExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = incOrDecExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(expr) <- incOrDecExpr.GetExpr()) {
            transNoTerminalExpr(expr)
        }
        resetGlobalVariables(ret, innerCmts)

        let opKind = getSyntaxImplKind(incOrDecExpr.GetOperatorKind())
        transBasicTerminal(incOrDecExpr.GetOperatorPos(), opKind)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.IncOrDecExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transParenExpr(parenExpr: SyntaxFormat_ParenExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(parenExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = parenExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(parenExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

        if (let Some(expr) <- parenExpr.GetExpr()) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(parenExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ParenExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transIsExpr(isExpr: SyntaxFormat_IsExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(isExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = isExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(expr) <- isExpr.GetExpr()) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }

        transBasicTerminal(isExpr.GetIsPos(), SyntaxNodeKind.IsToken)
        if (let Some(tp) <- isExpr.GetIsType()) {
            transType(tp)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.IsExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transAsExpr(asExpr: SyntaxFormat_AsExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(asExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = asExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(expr) <- asExpr.GetExpr()) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }

        transBasicTerminal(asExpr.GetAsPos(), SyntaxNodeKind.AsToken)
        if (let Some(tp) <- asExpr.GetAsType()) {
            transType(tp)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.AsExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transTypeConvExpr(typeConvExpr: SyntaxFormat_TypeConvExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(typeConvExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = typeConvExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(tp) <- typeConvExpr.GetType()) {
            transType(tp)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(typeConvExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

        if (let Some(expr) <- typeConvExpr.GetExpr()) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(typeConvExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TypeConvExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transOptionalExpr(optionalExpr: SyntaxFormat_OptionalExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(optionalExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = optionalExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(baseExpr) <- optionalExpr.GetBaseExpr()) {
            transNoTerminalExpr(baseExpr)
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(optionalExpr.GetQuestPos(), SyntaxNodeKind.QuestToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.OptionalExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transOptionalChainExpr(optionalChainExpr: SyntaxFormat_OptionalChainExpr,
        preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        if (let Some(expr) <- optionalChainExpr.GetExpr()) {
            return transExpr(expr)
        }
        None
    }

    private func transAssignExpr(assignExpr: SyntaxFormat_AssignExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(assignExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = assignExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(lhs) <- assignExpr.GetLeftValue()) {
            transNoTerminalExpr(lhs)
        }
        resetGlobalVariables(ret, innerCmts)

        let assignOpKind = getSyntaxImplKind(assignExpr.GetAssignOp())
        transBasicTerminal(assignExpr.GetAssignPos(), assignOpKind)

        if (let Some(rhs) <- assignExpr.GetRightExpr()) {
            transNoTerminalExpr(rhs)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.AssignExpr, ret.toArray(), preChildren: preChildren)
    }

    private func isCompilerAddUnitLiteral(expr: SyntaxFormat_Expr): Bool {
        if (let Some(lit) <- expr.GetExprAsLitConstExpr() && lit.GetLiteralConstKind() == 7 /*UNIT*/ ) {
            if (let Some(db) <- lit.GetBase()) {
                let beg = db.GetBegin()
                let end = db.GetEnd()
                if (beg.line == end.line && beg.column == end.column) {
                    return true
                }
            }
        }
        return false
    }

    private func transReturnExpr(returnExpr: SyntaxFormat_ReturnExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(returnExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = returnExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(returnExpr.GetReturnPos(), SyntaxNodeKind.ReturnToken)
        if (let Some(expr) <- returnExpr.GetExpr()) {
            // special case: return (), () is compiler add node
            if (!isCompilerAddUnitLiteral(expr)) {
                transNoTerminalExpr(expr)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ReturnExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transJumpExpr(jumpExpr: SyntaxFormat_JumpExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        var kind = SyntaxNodeKind.BreakToken
        var jumpKind = SyntaxNodeKind.BreakExpr
        if (!jumpExpr.GetIsBreak()) {
            kind = SyntaxNodeKind.ContinueToken
            jumpKind = SyntaxNodeKind.ContinueExpr
        }
        addWhitespaceAndMoveCursorToBegin(jumpExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = jumpExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- jumpExpr.GetBase()) {
            transBasicTerminal(db.GetBegin(), kind)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(jumpKind, ret.toArray(), preChildren: preChildren)
    }

    private func transSymbolRef4MemberAccess(memberAccess: SyntaxFormat_MemberAccess): ?SyntaxNodeImpl {
        let beginPos = memberAccess.GetFieldPos()
        addWhitespaceAndMoveCursor(beginPos)
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        transIdentifier(memberAccess.GetFieldPos(), memberAccess.GetField())

        var typeArguments = memberAccess.GetTypeArguments()
        if (typeArguments.size != 0) {
            addChild(ret,
                transTypeArguments(typeArguments, memberAccess.GetLeftAnglePos(), memberAccess.GetRightAnglePos()))
        }
        builder.buildNonTerminal(SyntaxNodeKind.RefExpr, ret.toArray())
    }

    private func transMemberAccess(memberAccess: SyntaxFormat_MemberAccess, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(memberAccess.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = memberAccess.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(baseExpr) <- memberAccess.GetBaseExpr()) {
            transNoTerminalExpr(baseExpr)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(memberAccess.GetDotPos(), SyntaxNodeKind.DotToken)
        addChild(ret, transSymbolRef4MemberAccess(memberAccess))
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.MemberAccess, ret.toArray(), preChildren: preChildren)
    }

    private func transSubscriptExpr(subscriptExpr: SyntaxFormat_SubscriptExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(subscriptExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = subscriptExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(baseExpr) <- subscriptExpr.GetBaseExpr()) {
            transNoTerminalExpr(baseExpr)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(subscriptExpr.GetLeftSquarePos(), SyntaxNodeKind.LSquareToken)

        let children = subscriptExpr.GetIndexExprs()
        let commasPos = subscriptExpr.GetCommaPosVec()
        for (i in 0..children.size) {
            if (let Some(expr) <- children[i]) {
                transNoTerminalExpr(expr)
                curChildren = ret
                if (i < commasPos.size) {
                    transBasicTerminal(commasPos[i], SyntaxNodeKind.CommaToken)
                }
            }
        }

        transBasicTerminal(subscriptExpr.GetRightSquarePos(), SyntaxNodeKind.RSquareToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.SubscriptExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transLambda(lambdaExpr: SyntaxFormat_LambdaExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(lambdaExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = lambdaExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(base) <- lambdaExpr.GetBase()) {
            transBasicTerminal(base.GetBegin(), SyntaxNodeKind.LCurlToken)
        }

        if (let Some(funcBody) <- lambdaExpr.GetBody()) {
            if (let Some(paramList) <- funcBody.GetParamList()) {
                addChild(ret, transParamList(paramList, isLambda: true))
                moveCursorToEnd(paramList.GetBase())
            }
            resetGlobalVariables(ret, innerCmts)
            transBasicTerminal(funcBody.GetArrowPos(), SyntaxNodeKind.DoubleArrowToken)

            if (let Some(blockNode) <- funcBody.GetBody()) {
                var body = blockNode.GetBody()
                for (node in getElements<SyntaxFormat_Node>(body)) {
                    addChild(ret, transRoot(node))
                    resetGlobalVariables(ret, innerCmts)
                }
                transBasicTerminal(blockNode.GetRightCurlPos(), SyntaxNodeKind.RCurlToken)
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.Lambda, ret.toArray(), preChildren: preChildren)
    }

    private func transThrowExpr(throwExpr: SyntaxFormat_ThrowExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(throwExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = throwExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(base) <- throwExpr.GetBase()) {
            transBasicTerminal(base.GetBegin(), SyntaxNodeKind.ThrowToken)
        }
        if (let Some(expr) <- throwExpr.GetExpr()) {
            transNoTerminalExpr(expr)
        }
        resetGlobalVariables(ret, innerCmts)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ThrowExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transSynchronizedExpr(synchronizedExpr: SyntaxFormat_SynchronizedExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(synchronizedExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = synchronizedExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(synchronizedExpr.GetSyncPos(), SyntaxNodeKind.SynchronizedToken)

        transBasicTerminal(synchronizedExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

        if (let Some(expr) <- synchronizedExpr.GetMutexExpr()) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }

        transBasicTerminal(synchronizedExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)

        if (let Some(block) <- synchronizedExpr.GetBody()) {
            addChild(ret, transBlock(block))
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.SynchronizedExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transSpawnExpr(spawnExpr: SyntaxFormat_SpawnExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(spawnExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = spawnExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(spawnExpr.GetSpawnPos(), SyntaxNodeKind.SpawnToken)

        if (spawnExpr.GetHasArg()) {
            transBasicTerminal(spawnExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
            if (let Some(expr) <- spawnExpr.GetSpawnArgExpr()) {
                transNoTerminalExpr(expr)
                resetGlobalVariables(ret, innerCmts)
            }
            transBasicTerminal(spawnExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        }

        if (let Some(expr) <- spawnExpr.GetTaskExpr()) {
            transNoTerminalExpr(expr)
        }
        resetGlobalVariables(ret, innerCmts)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.SpawnExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transIfExpr(ifExpr: SyntaxFormat_IfExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        // IF NL* LPAREN NL* condition NL* RPAREN NL* block (NL* ELSE (NL* ifExpression | NL* block))?
        addWhitespaceAndMoveCursorToBegin(ifExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = ifExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(ifExpr.GetIfPos(), SyntaxNodeKind.IfToken)
        transBasicTerminal(ifExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        if (let Some(expr) <- ifExpr.GetCondExpr()) {
            addChild(ret, transDisjunctionCondition(expr))
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(ifExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)

        if (let Some(block) <- ifExpr.GetBody()) {
            addChild(ret, transBlock(block))
        }

        if (ifExpr.GetHasElse()) {
            resetGlobalVariables(ret, innerCmts)
            transBasicTerminal(ifExpr.GetElsePos(), SyntaxNodeKind.ElseToken)
            if (let Some(elseBody) <- ifExpr.GetElseBody()) {
                // BlockExpr or IfExpr
                addChild(ret, transExpr(elseBody))
            }
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.IfExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transWhileExpr(whileExpr: SyntaxFormat_WhileExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(whileExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = whileExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(whileExpr.GetWhilePos(), SyntaxNodeKind.WhileToken)
        transBasicTerminal(whileExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        if (let Some(expr) <- whileExpr.GetCondExpr()) {
            addChild(ret, transDisjunctionCondition(expr))
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(whileExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (let Some(block) <- whileExpr.GetBody()) {
            addChild(ret, transBlock(block))
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.WhileExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transDoWhileExpr(doWhileExpr: SyntaxFormat_DoWhileExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(doWhileExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = doWhileExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(doWhileExpr.GetDoPos(), SyntaxNodeKind.DoToken)
        if (let Some(block) <- doWhileExpr.GetBody()) {
            addChild(ret, transBlock(block))
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(doWhileExpr.GetWhilePos(), SyntaxNodeKind.WhileToken)
        transBasicTerminal(doWhileExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        if (let Some(expr) <- doWhileExpr.GetCondExpr()) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(doWhileExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.DoWhileExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transForInExpr(forInExpr: SyntaxFormat_ForInExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(forInExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = forInExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(base) <- forInExpr.GetBase()) {
            transBasicTerminal(base.GetBegin(), SyntaxNodeKind.ForToken)
        }
        transBasicTerminal(forInExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        if (let Some(pattern) <- forInExpr.GetPattern()) {
            addChild(ret, transPattern(pattern))
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(forInExpr.GetInPos(), SyntaxNodeKind.InToken)
        if (let Some(inExpr) <- forInExpr.GetInExpr()) {
            addChild(ret, transExpr(inExpr))
            resetGlobalVariables(ret, innerCmts)
        }
        if (let Some(patternGuard) <- forInExpr.GetPatternGuard()) {
            transBasicTerminal(forInExpr.GetIfPos(), SyntaxNodeKind.WhereToken)
            addChild(ret, transExpr(patternGuard))
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(forInExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (let Some(block) <- forInExpr.GetBody()) {
            addChild(ret, transBlock(block))
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ForInExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transFuncArg(argument: SyntaxFormat_FuncArg): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = argument.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transIdentifier(argument.GetNamePos(), argument.GetName())
        transBasicTerminal(argument.GetColonPos(), SyntaxNodeKind.ColonToken)
        if (argument.GetWithInout()) {
            transBasicTerminal(argument.GetInoutPos(), SyntaxNodeKind.InoutToken)
        }
        if (let Some(expr) <- argument.GetExpr()) {
            transNoTerminalExpr(expr)
            resetGlobalVariables(ret, innerCmts)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.Argument, ret.toArray())
    }

    private func transCallExpr(callExpr: SyntaxFormat_CallExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(callExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = callExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        // baseFunc
        if (let Some(baseFunc) <- callExpr.GetBaseFunc()) {
            transNoTerminalExpr(baseFunc)
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(callExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
        // funcArgs
        let args = callExpr.GetArgs()
        for (p in args) {
            if (let Some(arg) <- p) {
                addWhitespaceAndMoveCursorToBegin(arg.GetBase())
                addChild(ret, transFuncArg(arg))
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(arg.GetCommaPos(), SyntaxNodeKind.CommaToken)
            }
        }
        resetGlobalVariables(ret, innerCmts)
        transBasicTerminal(callExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.CallExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transUnaryExpr(unExpr: SyntaxFormat_UnaryExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(unExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = unExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let opKind = getSyntaxImplKind(unExpr.GetOperatorKind())
        transBasicTerminal(unExpr.GetOperatorPos(), opKind)
        if (let Some(expr) <- unExpr.GetExpr()) {
            transNoTerminalExpr(expr)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.UnaryExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transBinaryExpr(biExpr: SyntaxFormat_BinaryExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(biExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = biExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(lhs) <- biExpr.GetLeftExpr()) {
            transNoTerminalExpr(lhs)
            resetGlobalVariables(ret, innerCmts)
        }
        resetGlobalVariables(ret, innerCmts)

        let opKind = getSyntaxImplKind(biExpr.GetOperatorKind())
        transBasicTerminal(biExpr.GetOperatorPos(), opKind)
        if (let Some(rhs) <- biExpr.GetRightExpr()) {
            transNoTerminalExpr(rhs)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.BinaryExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transInterpolationExpr(interpolationExpr: SyntaxFormat_InterpolationExpr,
        preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let base = interpolationExpr.GetBase()
        moveCursorToBegin(base)
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = interpolationExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(interpolationExpr.GetDollarPos(), SyntaxNodeKind.DollarToken)
        if (let Some(block) <- interpolationExpr.GetBlock()) {
            addChild(ret, transBlock(block))
            resetGlobalVariables(ret, innerCmts)
        }
        moveCursorToEnd(base)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.InterpolationExpr, ret.toArray(), preChildren: preChildren)
    }

    private func buildLineStringLiteral(nodeBase: ?SyntaxFormat_NodeBase, value: ValuedTerminal, isSingle: Bool,
        interpols: Array<Option<SyntaxFormat_Expr>>, preChildren: Array<SyntaxNodeImpl>, isInterpol!: Bool = false): NonTerminal {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let quoteToken = builder.buildQuote(isSingle)
        if (isInterpol) {
            ret.add(value)
        } else {
            ret.add(quoteToken)
            moveCursorColumn()
            if (interpols.size == 0) {
                ret.add(value)
                moveCursorColumn(col: Int32(value.value.size))
            }
            for (interpol in interpols) {
                if (let Some(interp) <- interpol) {
                    addChild(ret, transExpr(interp, isInterpol: true))
                    resetGlobalVariables(ret, innerCmts)
                }
            }
            ret.add(quoteToken)
            moveCursorColumn()
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        builder.buildNonTerminal(SyntaxNodeKind.LineStringLiteral, ret.toArray(), preChildren: preChildren)
    }

    private func buildMultiLineStringLiteral(lit: SyntaxFormat_LitConstExpr, value: ValuedTerminal, isSingle: Bool,
        interpols: Array<Option<SyntaxFormat_Expr>>, preChildren: Array<SyntaxNodeImpl>, isInterpol!: Bool = false): NonTerminal {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        let nodeBase = lit.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let quoteToken = builder.buildTripleQuote(isSingle)
        if (isInterpol) {
            ret.add(value)
        } else {
            ret.add(quoteToken)
            moveCursorColumn(col: 3)
            ret.add(builder.buildNewline(1))
            moveCursorLine()
            if (interpols.size == 0) {
                ret.add(value)
            }
            for (interpol in interpols) {
                if (let Some(interp) <- interpol) {
                    addChild(ret, transExpr(interp, isInterpol: true))
                }
            }
            ret.add(quoteToken)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        builder.buildNonTerminal(SyntaxNodeKind.MultiLineStringLiteral, ret.toArray(), preChildren: preChildren)
    }

    private func transLitConst(lit: SyntaxFormat_LitConstExpr, preChildren: Array<SyntaxNodeImpl>,
        isInterpol!: Bool = false): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(lit.GetBase())

        let literal = lit.GetLiteral()
        let kind = lit.GetLiteralConstKind()
        let strKind = lit.GetStringKind()
        let isSingle = lit.GetIsSingleQuote()
        let litToken = builder.buildValuedTerminal(SyntaxNodeKind.StringLiteralToken, literal)
        let interpols = lit.GetInterpol()
        if (isInterpol && literal == "") { // filter empty value part in the end (if there is)
            return None
        }
        let ret = match (kind) {
            case 0 /*INTEGER*/ => transValuedLiteral(lit, preChildren)
            case 1 /*RUNE_BYTE*/ => throw Exception("Rune Byte literal is not supported in syntax")
            case 2 /*FLOAT*/ => transValuedLiteral(lit, preChildren)
            case 3 /*RUNE*/ => buildRuneLiteral(lit, litToken, isSingle)
            case 4 /*STRING*/ => match (strKind) {
                case 0 /*NORMAL*/ => buildLineStringLiteral(lit.GetBase(), litToken, isSingle, interpols, preChildren,
                    isInterpol: isInterpol)
                // JString is processed before case
                // case 1 /*JSTRING*/ => builder.buildValuedTerminal(SyntaxNodeKind.JStringLiteralToken, literal)
                case 2 /*MULTILINE*/ => buildMultiLineStringLiteral(lit, litToken, isSingle, interpols, preChildren,
                    isInterpol: isInterpol)
                case 3 /*MULTILINE_RAW*/ => buildMultiLineRawStringLiteral(lit, litToken, Int64(lit.GetDelimiterNum()), isSingle)
                case _ => builder.buildInvalidTerminal() // JString is processed before case
            }
            case 5 /*JSTRING*/ => builder.buildValuedTerminal(SyntaxNodeKind.JStringLiteralToken, literal)
            case 6 /*BOOL*/ => transValuedLiteral(lit, preChildren)
            case 7 /*UNIT*/ => transUnitLiteral(lit, preChildren)
            case _ => builder.buildInvalidTerminal() /* or return none*/
        }
        if (!isInterpol) {
            moveCursorToEnd(lit.GetBase())
        }
        ret
    }

    func buildRuneLiteral(lit: SyntaxFormat_LitConstExpr, value: ValuedTerminal, isSingle: Bool,
        preChildren!: Array<SyntaxNodeImpl> = []): NonTerminal {
        let ret = ArrayList<SyntaxNodeImpl>(preChildren)
        let nodeBase = lit.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let quoteToken = builder.buildQuote(isSingle)
        let prefix = builder.buildBasicTerminal(SyntaxNodeKind.RunePrefixToken)
        ret.add(all: [prefix, quoteToken, value, quoteToken])
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        builder.buildNonTerminal(SyntaxNodeKind.RuneLiteral, ret.toArray())
    }

    func buildMultiLineRawStringLiteral(lit: SyntaxFormat_LitConstExpr, value: ValuedTerminal, delimiterNum: Int64,
        isSingle: Bool, preChildren!: Array<SyntaxNodeImpl> = []): NonTerminal {
        let ret = ArrayList<SyntaxNodeImpl>(preChildren)
        let nodeBase = lit.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let quoteToken = builder.buildQuote(isSingle)
        let hashToken = builder.buildHash(delimiterNum)
        ret.add(all: [hashToken, quoteToken, value, quoteToken, hashToken])
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        builder.buildNonTerminal(SyntaxNodeKind.MultiLineRawStringLiteral, ret.toArray())
    }

    private func transValuedLiteral(lit: SyntaxFormat_LitConstExpr, preChildren: Array<SyntaxNodeImpl>): SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = lit.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let literal = lit.GetLiteral()
        let kind = lit.GetLiteralConstKind()
        let kindNode = match (kind) {
            case 0 /*INTEGER*/ => builder.buildValuedTerminal(SyntaxNodeKind.IntegerLiteralToken, literal)
            case 2 /*FLOAT*/ => builder.buildValuedTerminal(SyntaxNodeKind.FloatLiteralToken, literal)
            case 5 /*JSTRING*/ => builder.buildValuedTerminal(SyntaxNodeKind.JStringLiteralToken, literal)
            case 6 /*BOOL*/ => builder.buildValuedTerminal(SyntaxNodeKind.BooleanLiteralToken, literal)
            case _ => builder.buildInvalidTerminal() /* or return none*/
        }

        addChild(ret, kindNode)
        moveCursorColumn(col: Int32(literal.size))
        addWhitespaceAndMoveCursorToEnd(lit.GetBase())

        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ValuedLiteral, ret.toArray(), preChildren: preChildren)
    }

    private func transUnitLiteral(lit: SyntaxFormat_LitConstExpr, preChildren: Array<SyntaxNodeImpl>): SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = lit.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        ret.add(builder.buildBasicTerminal(SyntaxNodeKind.LParenToken))
        moveCursorColumn()
        addWhitespaceAndMoveCursorToEnd(lit.GetBase())
        ret.add(builder.buildBasicTerminal(SyntaxNodeKind.RParenToken))
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.UnitLiteral, ret.toArray(), preChildren: preChildren)
    }

    private func transLetPattern(letPattern: SyntaxFormat_LetPatternDestructor, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(letPattern.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = letPattern.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(db) <- letPattern.GetBase()) {
            transBasicTerminal(db.GetBegin(), SyntaxNodeKind.LetToken)
        }

        let patterns = letPattern.GetPatterns()
        let bitOrTokens = letPattern.GetBitOrPosVec()

        for (i in 0..patterns.size) {
            if (let Some(pattern) <- patterns[i]) {
                addChild(ret, transPattern(pattern))
                resetGlobalVariables(ret, innerCmts)
                if (i < bitOrTokens.size) {
                    transBasicTerminal(bitOrTokens[i], SyntaxNodeKind.BitOrToken)
                }
            }
        }

        resetGlobalVariables(ret, innerCmts)

        transBasicTerminal(letPattern.GetBackarrowPos(), SyntaxNodeKind.BackArrowToken)

        if (let Some(expr) <- letPattern.GetInitializer()) {
            transNoTerminalExpr(expr)
        }
        resetGlobalVariables(ret, innerCmts)
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.LetPattern, ret.toArray(), preChildren: preChildren)
    }

    // recursively parse the OR expressions in the DisjunctionCondition
    private func createOr(ret: ArrayList<SyntaxNodeImpl>, cond: SyntaxFormat_Expr): Unit {
        // current Expr is BinaryExpr and opkind is OR, split the Expr to two ConjunctionCond
        if (let Some(binaryExpr) <- cond.GetExprAsBinaryExpr() && getSyntaxImplKind(binaryExpr.GetOperatorKind()) == SyntaxNodeKind
            .OrToken) {
            if (let Some(lhs) <- binaryExpr.GetLeftExpr()) {
                createOr(ret, lhs)
                curChildren = ret
            }
            transBasicTerminal(binaryExpr.GetOperatorPos(), SyntaxNodeKind.OrToken)
            if (let Some(rhs) <- binaryExpr.GetRightExpr()) {
                createOr(ret, rhs)
                curChildren = ret
            }
        } else {
            // parse current expr as one ConjunctionCond
            addChild(ret, transConjunctionCondition(cond))
            curChildren = ret
        }
    }

    // parse left expr and right expr to AtomicConds separately
    private func createAnd(ret: ArrayList<SyntaxNodeImpl>, binaryExpr: SyntaxFormat_BinaryExpr): Unit {
        if (let Some(lhs) <- binaryExpr.GetLeftExpr()) {
            createAtomicCond(ret, lhs)
            curChildren = ret
        }
        transBasicTerminal(binaryExpr.GetOperatorPos(), SyntaxNodeKind.AndToken)
        if (let Some(rhs) <- binaryExpr.GetRightExpr()) {
            createAtomicCond(ret, rhs)
            curChildren = ret
        }
    }

    // recursively parse the AtomicCondition in the ConjunctionCondition
    // BNF: | letpattern | parenCond | expr
    private func createAtomicCond(ret: ArrayList<SyntaxNodeImpl>, cond: SyntaxFormat_Expr): Unit {
        curChildren = ret
        // current Expr is BinaryExpr and opkind is AND, split the Expr to two AtomicCond
        if (let Some(binaryExpr) <- cond.GetExprAsBinaryExpr() && getSyntaxImplKind(binaryExpr.GetOperatorKind()) == SyntaxNodeKind
            .AndToken) {
            createAnd(ret, binaryExpr)
        } else if (let Some(parenExpr) <- cond.GetExprAsParenExpr()) {
            // current Expr is ParenExpr, parse it as parenCond
            addChild(ret, transParenCondition(parenExpr))
            curChildren = ret
        } else {
            // parse current expr as one AtomicCond
            transNoTerminalExpr(cond)
        }
    }

    // BNF: conjunctionCond ||  conjunctionCond  || conjunctionCond ...
    private func transDisjunctionCondition(disjunctionCondition: SyntaxFormat_Expr): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(disjunctionCondition.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        createOr(ret, disjunctionCondition)
        builder.buildNonTerminal(SyntaxNodeKind.DisjunctionCondition, ret.toArray())
    }

    // BNF: atomicCond && atomicCond && atomicCond ...
    private func transConjunctionCondition(conjunctionCondition: SyntaxFormat_Expr): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(conjunctionCondition.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        createAtomicCond(ret, conjunctionCondition)
        builder.buildNonTerminal(SyntaxNodeKind.ConjunctionCondition, ret.toArray())
    }

    // BNF: ( disjunctionCond )
    private func transParenCondition(parenCondition: SyntaxFormat_ParenExpr): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(parenCondition.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = parenCondition.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        transBasicTerminal(parenCondition.GetLeftParenPos(), SyntaxNodeKind.LParenToken)

        if (let Some(expr) <- parenCondition.GetExpr()) {
            addChild(ret, transDisjunctionCondition(expr))
            resetGlobalVariables(ret, innerCmts)
        }
        transBasicTerminal(parenCondition.GetRightParenPos(), SyntaxNodeKind.RParenToken)

        moveCursorToEnd(parenCondition.GetBase())
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.ParenCondition, ret.toArray())
    }

    private func transQuoteTokenExpr(tokenPart: SyntaxFormat_TokenPart, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret
        for (tk in tokenPart.GetTokens()) {
            if (let Some(v) <- tk) {
                transTokenTerminal(v.GetPos(), getTokenKind(v.GetKind()), v.GetValue(), needNewLine: false,
                    delimiterNum: v.GetDelimiterNum(), isSingleQuote: v.GetIsSingleQuote(), hasEscape: v.GetHasEscape())
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.QuoteTokenExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transQuoteInterpolationExpr(expr: SyntaxFormat_Expr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = expr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        let table = expr.table
        let o: UInt16 = table.offset(expr.EXPR)
        let off: UInt32 = UInt32(o) + table.pos
        match (expr.GetExprType()) {
            case SyntaxFormat_AnyExpr.AnyExpr_REF_EXPR =>
                ret.add(builder.buildBasicTerminal(SyntaxNodeKind.DollarToken))
                addChild(ret, transExpr(expr))
                moveCursorToEnd(expr.GetBase())
            case SyntaxFormat_AnyExpr.AnyExpr_PAREN_EXPR =>
                let parenExpr = SyntaxFormat_ParenExpr(table.bytes, off)
                if (let Some(base) <- parenExpr.GetBase()) {
                    transBasicTerminal(base.GetBegin(), SyntaxNodeKind.DollarToken)
                }
                transBasicTerminal(parenExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
                if (let Some(expr1) <- parenExpr.GetExpr()) {
                    addChild(ret, transExpr(expr1))
                    curChildren = ret
                }
                transBasicTerminal(parenExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
            case _ => ()
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.QuoteInterpolationExpr, ret.toArray(), preChildren: preChildren)
    }

    func moveCursorByExpr(expr: SyntaxFormat_Expr): Unit {
        if (let Some(base) <- expr.GetBase()) {
            let begin = base.GetBegin()
            let (beginLine, beginColumn) = match (expr.GetExprType()) {
                case SyntaxFormat_AnyExpr.AnyExpr_REF_EXPR => (begin.line, begin.column - 1)
                case _ => (begin.line, begin.column)
            }
            addWhitespace(beginLine, beginColumn, needNewLine: false)
            // move cursor
            (cursorLine, cursorColumn) = (beginLine, beginColumn)
        }
    }

    private func transQuoteExpr(quoteExpr: SyntaxFormat_QuoteExpr, preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(quoteExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = quoteExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(exprBase) <- quoteExpr.GetBase()) {
            transBasicTerminal(exprBase.GetBegin(), SyntaxNodeKind.QuoteToken)
            transBasicTerminal(quoteExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
            let children = quoteExpr.GetExprs()
            for (expr in getElements<SyntaxFormat_Expr>(children)) {
                moveCursorByExpr(expr)
                let expr1 = match (expr.GetExprType()) {
                    case SyntaxFormat_AnyExpr.AnyExpr_TOKEN_PART => transExpr(expr)
                    case _ => transQuoteInterpolationExpr(expr)
                }
                addChild(ret, expr1)
                resetGlobalVariables(ret, innerCmts)
            }
            transBasicTerminal(quoteExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.QuoteExpr, ret.toArray(), preChildren: preChildren)
    }

    private func transTrailingClosureExpr(trailingClosureExpr: SyntaxFormat_TrailingClosureExpr,
        preChildren: Array<SyntaxNodeImpl>): ?SyntaxNodeImpl {
        addWhitespaceAndMoveCursorToBegin(trailingClosureExpr.GetBase())
        let ret = ArrayList<SyntaxNodeImpl>()
        addLeadCommentNodesToRet(ret)
        curChildren = ret

        let nodeBase = trailingClosureExpr.GetBase()
        let (leadCmts, innerCmts, trailCmts) = getCommentGroups(nodeBase)
        addLeadingComments(nodeBase, ret, leadCmts)
        innerComments = innerCmts

        if (let Some(expr) <- trailingClosureExpr.GetExpr()) {
            if (let Some(callExpr) <- expr.GetExprAsCallExpr()) {
                addWhitespaceAndMoveCursorToBegin(callExpr.GetBase())
                // baseFunc
                if (let Some(baseFunc) <- callExpr.GetBaseFunc()) {
                    transNoTerminalExpr(baseFunc)
                    resetGlobalVariables(ret, innerCmts)
                }
                transBasicTerminal(callExpr.GetLeftParenPos(), SyntaxNodeKind.LParenToken)
                // funcArgs
                let args = callExpr.GetArgs()
                for (arg in getElements<SyntaxFormat_FuncArg>(args)) {
                    addWhitespaceAndMoveCursorToBegin(arg.GetBase())
                    addChild(ret, transFuncArg(arg))
                    resetGlobalVariables(ret, innerCmts)
                    transBasicTerminal(arg.GetCommaPos(), SyntaxNodeKind.CommaToken)
                }
                resetGlobalVariables(ret, innerCmts)
                transBasicTerminal(callExpr.GetRightParenPos(), SyntaxNodeKind.RParenToken)
                moveCursorToEnd(callExpr.GetBase())
            } else if (let Some(refExpr) <- expr.GetExprAsRefExpr()) {
                addChild(ret, transRefExpr(refExpr))
                moveCursorToEnd(refExpr.GetBase())
                resetGlobalVariables(ret, innerCmts)
            } else if (let Some(memberAccess) <- expr.GetExprAsMemberAccess()) {
                addChild(ret, transMemberAccess(memberAccess))
                moveCursorToEnd(memberAccess.GetBase())
                resetGlobalVariables(ret, innerCmts)
            }
        }
        if (let Some(lambda) <- trailingClosureExpr.GetLambda()) {
            addChild(ret, transLambda(lambda))
            moveCursorToEnd(lambda.GetBase())
            resetGlobalVariables(ret, innerCmts)
        }
        if (trailCmts.size > 0) {
            addChild(ret, transCommentGroupList(trailCmts))
            resetGlobalVariables(ret, innerCmts)
        }
        innerComments = Array<Option<SyntaxFormat_CommentGroup>>()
        builder.buildNonTerminal(SyntaxNodeKind.TrailingClosureExpr, ret.toArray(), preChildren: preChildren)
    }

    private func getCommentGroups(nodeBase: ?SyntaxFormat_NodeBase) {
        if (let Some(node) <- nodeBase && let Some(cmts) <- node.GetComments()) {
            (cmts.GetLeadingComments(), cmts.GetInnerComments(), cmts.GetTrailingComments())
        } else {
            (Array<Option<SyntaxFormat_CommentGroup>>(), Array<Option<SyntaxFormat_CommentGroup>>(),
                Array<Option<SyntaxFormat_CommentGroup>>())
        }
    }

    private func getCommentGroupListBeginPos(groupList: Array<Option<SyntaxFormat_CommentGroup>>): ?SyntaxFormat_Position {
        if (groupList.size > 0) {
            let beginCmtGroup = groupList[0].getOrThrow()
            if (beginCmtGroup.GetCms().size > 0 && let Some(beginComment) <- beginCmtGroup.GetCms()[0] && let Some(tk) <- beginComment
                .GetInfo()) {
                return tk.GetPos()
            }
        }
        None
    }

    private func addLeadingComments(nodeBase: ?SyntaxFormat_NodeBase, ret: ArrayList<SyntaxNodeImpl>,
        leadCmts: Array<Option<SyntaxFormat_CommentGroup>>, isDecl!: Bool = false) {
        if (leadCmts.size > 0 && let Some(beginPos) <- getCommentGroupListBeginPos(leadCmts) && let Some(node) <- nodeBase) {
            addWhitespaceAndMoveCursor(beginPos)
            curChildren = ret
            addChild(ret, transCommentGroupList(leadCmts))
            curChildren = ret
            if (!isDecl) {
                addWhitespaceAndMoveCursor(node.GetBegin())
            }
        }
    }

    private func addLeadCommentNodesToRet(ret: ArrayList<SyntaxNodeImpl>) {
        if (leadCommentNodes.size > 0) {
            ret.add(all: leadCommentNodes)
            leadCommentNodes = ArrayList<SyntaxNodeImpl>()
        }
    }

    private func addTrailCommentNodesToRet(ret: ArrayList<SyntaxNodeImpl>,
        innerCmts: Array<Option<SyntaxFormat_CommentGroup>>) {
        if (trailComments.size > 0) {
            addChild(ret, transCommentGroupList(trailComments))
            trailComments = Array<Option<SyntaxFormat_CommentGroup>>()
            resetGlobalVariables(ret, innerCmts)
        }
    }

    private func transCommentGroupList(groupList: Array<Option<SyntaxFormat_CommentGroup>>): ?SyntaxNodeImpl {
        if (groupList.size == 0) {
            return None
        }
        let ret = ArrayList<SyntaxNodeImpl>()
        curChildren = ret

        for (node in groupList) {
            curChildren = ret
            if (let Some(cmtGroup) <- node) {
                addChild(ret, transCommentGroup(cmtGroup))
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.CommentGroupList, ret.toArray())
    }

    private func transCommentGroup(commentGroup: SyntaxFormat_CommentGroup): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()
        let cmts: Array<Option<SyntaxFormat_Comment>> = commentGroup.GetCms()
        if (cmts.size > 0 && let Some(cmt) <- cmts[0] && let Some(v) <- cmt.GetInfo()) {
            let begin = v.GetPos()
            addWhitespaceAndMoveCursor(begin)
        } else {
            return builder.buildNonTerminal(SyntaxNodeKind.CommentGroup, ret.toArray())
        }

        curChildren = ret

        for (node in cmts) {
            curChildren = ret
            if (let Some(cmt) <- node) {
                addChild(ret, transComment(cmt))
            }
        }
        builder.buildNonTerminal(SyntaxNodeKind.CommentGroup, ret.toArray())
    }

    private func transComment(comment: SyntaxFormat_Comment): ?SyntaxNodeImpl {
        let ret = ArrayList<SyntaxNodeImpl>()

        if (let Some(v) <- comment.GetInfo()) {
            addWhitespaceAndMoveCursor(v.GetPos(), needNewLine: true)
            curChildren = ret
            transTokenTerminal(v.GetPos(), getTokenKind(v.GetKind()), v.GetValue(), needNewLine: true,
                delimiterNum: v.GetDelimiterNum(), isSingleQuote: v.GetIsSingleQuote(), hasEscape: v.GetHasEscape())
        }
        builder.buildNonTerminal(SyntaxNodeKind.Comment, ret.toArray())
    }
}
