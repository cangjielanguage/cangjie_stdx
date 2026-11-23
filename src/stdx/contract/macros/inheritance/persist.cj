/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.inheritance

import stdx.contract.macros.parse.{parseClassContract}
import stdx.contract.macros.syntax.{TypeClause}
import std.ast.{DiagReportLevel, FuncType, ParenType, PrefixType, PrimitiveType, QualifiedType, RefType, ThisType, Token, TokenKind, Tokens, TupleType, TypeNode, VArrayType, cangjieLex, diagReport}
import std.collection.{ArrayList, HashMap, HashSet, contains, isEmpty}
import std.env.{getProcessId, getVariable, getWorkingDirectory}
import std.fs.{Directory, File, FileInfo, OpenMode, Path, exists, remove, rename}
import std.convert.{Parsable}

/// Compile-time persistence of contract inheritance metadata: `@Contract` type macros publish
/// their `ContractMetaData` to `<meta-dir>/<fullName>.cmeta` (`fullName` is package-qualified
/// when `CANGJIE_STDX_CONTRACT_PKG_NAME` is set), written via a temporary file and one atomic
/// rename. Every record ends with an FNV-1a 64-bit content fingerprint (see
/// `metaDataFingerprint`) so a consumer recompiling against a parent that was rebuilt since
/// its last build can at least warn about the stale record.
/// Version 5 adds the `valueNames` section (parent value names kept intact when a child
/// instantiates inherited clause conditions); records of older versions are refused.
/// Version 6 extends every `MATTR` record with the member's ordered parameter names and its
/// checker base, so children rename inherited clause parameters positionally (#8) and
/// materialize ancestor conditions as public checker calls (#9); older records are refused.
/// Version 7 writes, before every origin type argument's token text, a marker for the concrete
/// `TypeNode` kind (`RefType` throws on primitive text, `PrimitiveType` on reference text), so
/// the read side rebuilds the same node kind instead of refusing the whole record; older
/// records are refused.
const META_FORMAT_VERSION: Int64 = 7
/// Probe cache: each requested name is looked up on disk at most once per cjc process, so the
/// disk access stays O(distinct names) instead of O(lookups).
/// Macro expansion may run in parallel: these globals are not thread-safe and must only be
/// touched while holding `_CONTRACT_META_REGISTRY_MUTEX` (see metadata.cj); all callers do.
let _META_DISK_PROBED = HashSet<String>()

/// Package name of the package currently being compiled. The macro API cannot query it, so the
/// build injects it through `CANGJIE_STDX_CONTRACT_PKG_NAME`. Without it, records keep the
/// simple-name identity and two packages declaring a same-named type share one record.
internal func contractPackageName(): String {
    match (getVariable("CANGJIE_STDX_CONTRACT_PKG_NAME")) {
        case Some(value) => value.trimAscii()
        case None => ""
    }
}

// ---------------------------------------------------------------------------
// public entry points (called from metadata.cj hooks)
// ---------------------------------------------------------------------------

/// One-shot flag for the persistence-failure WARNING below: a single broken setup (e.g. a
/// misconfigured `CANGJIE_STDX_CONTRACT_META_DIR`) would repeat the same failure for every
/// `@Contract`, so it is reported only once. Only touch this under `_CONTRACT_META_REGISTRY_MUTEX`.
var _persistFailureWarned = false

/// Best-effort write of one metadata record. Never throws; persistence problems must not
/// fail the user's compilation because the feature is additive. The first failure reports a
/// one-time WARNING so cross-package inheritance degrading silently stays diagnosable.
internal func persistMetaData(data: ContractMetaData): Unit {
    try {
        let dirs = metaDirCandidates()
        if (dirs.isEmpty()) {
            return
        }
        let dir = dirs[0]
        if (!exists(dir)) {
            Directory.create(dir, recursive: true)
        }
        let path = dir + "/" + metaFileName(data.fullName)
        // The temporary name carries the process id: two cjc processes may legitimately write the
        // same record at once (parallel builds of the same package), and a shared `<path>.tmp`
        // would let one truncate the other's file mid-write.
        let temp = path + "." + getProcessId().toString() + ".tmp"
        try {
            let file = File(temp, OpenMode.Write)
            try {
                file.write(serializeMetaData(data))
            } finally {
                file.close()
            }
            rename(temp, to: path, overwrite: true)
        } catch (e: Exception) {
            // Leave no partial temporary behind when the write or the final rename failed.
            try {
                remove(Path(temp))
            } catch (unused: Exception) {
                ()
            }
            throw e
        }
    } catch (e: Exception) {
        // Persistence failures must not break compilation, but they disable cross-package
        // inheritance, so the first one is surfaced as a WARNING (once per process).
        if (!_persistFailureWarned) {
            _persistFailureWarned = true
            diagReport(DiagReportLevel.WARNING, Tokens(),
                "contract inheritance metadata could not be persisted (${e}); cross-package " +
                "inheritance will be unavailable for this build",
                "check the CANGJIE_STDX_CONTRACT_META_DIR setting and the write permissions of the meta directory")
        }
    }
}

/// Map a fully qualified type name to its record file name. Dots are kept because they delimit
/// the package, while path separators and other file-system special characters become `_`.
func metaFileName(fullName: String): String {
    var name = fullName
    for (bad in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]) {
        name = name.replace(bad, "_")
    }
    name + ".cmeta"
}

/// Load and register-on-return the metadata for `name` from the configured meta directories.
/// Returns None when no record exists or the record cannot be rebuilt; a parseable-but-stale
/// record reports a WARNING diagnostic pointing at the record tokens.
internal func loadMetaDataFromDisk(name: String): ?ContractMetaData {
    var candidates = metaFileCandidates(name)
    if (candidates.size > 1) {
        // The same record may legitimately appear in several searched directories: cjpm builds
        // every dependency with the top-level module as working directory, so a parent library
        // built inside a workspace writes into the top-level `target/contract_meta` while a
        // standalone build of the same library leaves an identical copy in its own directory.
        // Byte-identical copies are one logical record; drop the duplicates before the
        // ambiguity check so only genuinely divergent records are reported.
        candidates = dedupeIdenticalRecords(candidates)
    }
    if (candidates.size > 1) {
        // Same-package records win over same-name records of other packages: a workspace
        // build and a dependency build can both leave a `<Name>.cmeta`, and picking the
        // foreign one would silently inherit the wrong contract. Only a still-ambiguous
        // selection is reported.
        let currentPackage = contractPackageName()
        if (currentPackage != "") {
            let preferred = metaFileName(currentPackage + "." + name)
            let samePackage = ArrayList<String>()
            for (path in candidates) {
                if (path.endsWith("/" + preferred) || path.endsWith("\\" + preferred)) {
                    samePackage.add(path)
                }
            }
            if (samePackage.size == 1) {
                candidates = samePackage
            }
        }
    }
    if (candidates.size > 1) {
        reportAmbiguousMeta(name, candidates)
        return None
    }
    for (path in candidates) {
        let bytes: ?Array<UInt8> = readWholeFileSafe(path)
        match (bytes) {
            case Some(value) =>
                return parseMetaData(name, value)
            case None => ()
        }
    }
    None
}

/// Drop candidates whose file content equals one already seen, keeping the first occurrence.
/// Unreadable entries never equal anything and survive deduplication.
func dedupeIdenticalRecords(candidates: ArrayList<String>): ArrayList<String> {
    let kept = ArrayList<String>()
    let seen = ArrayList<Array<UInt8>>()
    for (path in candidates) {
        var duplicate = false
        if (let Some(bytes) <- readWholeFileSafe(path)) {
            for (known in seen) {
                if (bytes == known) {
                    duplicate = true
                    break
                }
            }
            if (!duplicate) {
                seen.add(bytes)
            }
        }
        if (!duplicate) {
            kept.add(path)
        }
    }
    kept
}

/// Resolve the record files matching `name` across every meta directory. A qualified name maps
/// to one exact file; a simple name matches `<Name>.cmeta` as well as `<package>.<Name>.cmeta`,
/// so records written by package-aware builds stay readable from unqualified references.
func metaFileCandidates(name: String): ArrayList<String> {
    let candidates = ArrayList<String>()
    let qualified = name.contains(".")
    for (dir in metaDirCandidates()) {
        if (!exists(dir)) {
            continue
        }
        if (qualified) {
            let path = dir + "/" + metaFileName(name)
            if (exists(path)) {
                candidates.add(path)
            }
            continue
        }
        let plain = name + ".cmeta"
        let suffix = "." + name + ".cmeta"
        // Records are written flat into the meta directory, so one listing level is enough;
        // a recursive walk would only rescan unrelated subdirectories.
        try {
            for (info in Directory.readFrom(Path(dir))) {
                let fileName = info.name
                if (fileName == plain || fileName.endsWith(suffix)) {
                    candidates.add(info.path.toString())
                }
            }
        } catch (e: Exception) {
            // An unreadable directory behaves like a miss.
            ()
        }
    }
    candidates
}

/// A simple-name reference cannot pick between records of different packages; taking either
/// would silently inherit the wrong contract, so the caller skips inheritance entirely.
func reportAmbiguousMeta(name: String, candidates: ArrayList<String>): Unit {
    var detail = ""
    for (path in candidates) {
        if (detail != "") {
            detail += ", "
        }
        detail += path
    }
    diagReport(DiagReportLevel.WARNING, Tokens(),
        "ambiguous contract metadata for `${name}`: ${candidates.size} records match (${detail}); " +
        "qualify the parent type with its package name, or remove the stale record",
        "build the defining library with CANGJIE_STDX_CONTRACT_PKG_NAME so records carry package-qualified names")
}

/// Directories searched for `.cmeta` records. `CANGJIE_STDX_CONTRACT_META_DIR` is a `:`-separated list
/// (a single-letter segment is rejoined with the next one as a Windows drive prefix);
/// without it the cjpm default `<cwd>/target/contract_meta` is the write target, and the
/// `target/contract_meta` directories of the cjpm module's path dependencies are appended as
/// read-only search locations so cross-package inheritance works without extra setup.
/// The first entry is the write target; every entry is searched.
func metaDirCandidates(): ArrayList<String> {
    let dirs = ArrayList<String>()
    match (getVariable("CANGJIE_STDX_CONTRACT_META_DIR")) {
        case Some(value) =>
            // A single-letter entry is a Windows drive prefix, not a directory: rejoin
            // it with the next segment so `C:\cmeta` survives the `:` split.
            let parts = value.split(":")
            var index = 0
            while (index < parts.size) {
                var part = parts[index]
                if (isDrivePrefix(part) && index + 1 < parts.size) {
                    part = part + ":" + parts[index + 1]
                    index += 1
                }
                if (part != "") {
                    dirs.add(trimTrailingSeparators(part))
                }
                index += 1
            }
        case None =>
            dirs.add(trimTrailingSeparators(getWorkingDirectory().toString()) + "/target/contract_meta")
            for (dir in probeCjpmDependencyMetaDirs()) {
                if (!dirs.contains(dir)) {
                    dirs.add(dir)
                }
            }
    }
    dirs
}

// ---------------------------------------------------------------------------
// cjpm layout probing (default `CANGJIE_STDX_CONTRACT_META_DIR` only)
// ---------------------------------------------------------------------------

/// One-shot cache for cjpm layout probing (see `probeCjpmDependencyMetaDirs`): the project
/// layout cannot change mid-compilation. Only touch these globals while holding
/// `_CONTRACT_META_REGISTRY_MUTEX`; all callers run under it.
let _PROBED_CJPM_META_DIRS = ArrayList<String>()
var _cjpmMetaDirsProbed = false

/// Discover `target/contract_meta` directories of cjpm path dependencies so that a consumer
/// built by cjpm without `CANGJIE_STDX_CONTRACT_META_DIR` still finds its dependencies' contract records:
/// the module root is located by walking up from the working directory for `cjpm.toml`, and
/// every `path = "..."` entry of a dependencies section contributes `<dep>/target/contract_meta`.
/// Read-only and best-effort: missing files, unparsable lines and absent directories simply
/// contribute nothing, and the probe runs at most once per process.
func probeCjpmDependencyMetaDirs(): ArrayList<String> {
    if (_cjpmMetaDirsProbed) {
        return _PROBED_CJPM_META_DIRS
    }
    _cjpmMetaDirsProbed = true
    try {
        let cwd = trimTrailingSeparators(getWorkingDirectory().toString())
        if (let Some(root) <- findCjpmModuleRoot(cwd)) {
            appendExistingMetaDir(_PROBED_CJPM_META_DIRS, root)
            // `parseCjpmPathDependencies` returns ready `<dep>/target/contract_meta` candidates
            // (it already filtered out missing directories); just merge them in order.
            for (dep in parseCjpmPathDependencies(root)) {
                if (!_PROBED_CJPM_META_DIRS.contains(dep)) {
                    _PROBED_CJPM_META_DIRS.add(dep)
                }
            }
        }
    } catch (e: Exception) {
        // Probing is opportunistic: any failure leaves the default dirs in effect.
        ()
    }
    _PROBED_CJPM_META_DIRS
}

/// Walk up from `startDir` until a directory containing `cjpm.toml` is found. None when the
/// filesystem root is reached first (the compilation is not running inside a cjpm module).
func findCjpmModuleRoot(startDir: String): ?String {
    var dir = startDir
    var result: ?String = None
    while (true) {
        if (readWholeFileSafe(dir + "/cjpm.toml").isSome()) {
            result = Some(dir)
            break
        }
        let parent = parentOf(dir)
        if (parent == dir) {
            break
        }
        dir = parent
    }
    result
}

/// Parent directory of an absolute path; the result equals the input at the filesystem root
/// or for separator-free paths, which the caller treats as "no parent". Both separators are
/// accepted so the walk-up also works on Windows (`C:\dir` style paths).
func parentOf(dir: String): String {
    let bytes = dir.toArray()
    var index = bytes.size - 1
    while (index > 0 && bytes[index] != 47 && bytes[index] != 92) { // '/', '\'
        index -= 1
    }
    if (index <= 0) {
        return dir
    }
    dir[0..index]
}

/// Collect the path-dependency directories declared in `<moduleRoot>/cjpm.toml`. The file is
/// scanned line by line: any `[...]` section whose name contains "depend" enables extraction
/// of `path = "..."` values until the next section header. Deliberately coarse — a false
/// positive is harmless because only existing `<dir>/target/contract_meta` paths survive.
func parseCjpmPathDependencies(moduleRoot: String): ArrayList<String> {
    let result = ArrayList<String>()
    if (let Some(bytes) <- readWholeFileSafe(moduleRoot + "/cjpm.toml")) {
        var inDependencySection = false
        for (rawLine in String.fromUtf8(bytes).split("\n")) {
            let line = rawLine.trimAscii()
            if (line == "" || line.startsWith("#")) {
                continue
            }
            if (line.startsWith("[")) {
                inDependencySection = line.contains("depend")
                continue
            }
            if (!inDependencySection) {
                continue
            }
            if (let Some(declared) <- extractTomlPathValue(line)) {
                appendExistingMetaDir(result, resolveDependencyDir(moduleRoot, declared))
            }
        }
    }
    result
}

/// Extract the quoted value of a `path` key from one TOML line, e.g. `lib = { path = "./lib" }`.
/// The key must not be preceded by an identifier character, so keys like `classpath` do not match.
func extractTomlPathValue(line: String): ?String {
    let bytes = line.toArray()
    let start = findSubsequence(bytes, "path".toArray())
    match (start) {
        case Some(index) =>
            if (index > 0 && isIdentifierByte(bytes[index - 1])) {
                return None
            }
            var i = index + 4
            while (i < bytes.size && (bytes[i] == 32 || bytes[i] == 9)) { // space, tab
                i += 1
            }
            if (i >= bytes.size || bytes[i] != 61) { // '='
                return None
            }
            i += 1
            while (i < bytes.size && (bytes[i] == 32 || bytes[i] == 9)) {
                i += 1
            }
            if (i >= bytes.size || (bytes[i] != 34 && bytes[i] != 39)) { // '"' '\''
                return None
            }
            let quoteByte = bytes[i]
            var end = i + 1
            while (end < bytes.size && bytes[end] != quoteByte) {
                end += 1
            }
            if (end >= bytes.size) {
                return None
            }
            Some(line[i + 1..end])
        case None => None
    }
}

func isIdentifierByte(byte: UInt8): Bool {
    (byte >= 97 && byte <= 122) || (byte >= 65 && byte <= 90) || (byte >= 48 && byte <= 57) ||
        byte == 95 || byte == 45 // a-z, A-Z, 0-9, '_', '-'
}

func findSubsequence(data: Array<UInt8>, pattern: Array<UInt8>): ?Int64 {
    if (pattern.size == 0 || data.size < pattern.size) {
        return None
    }
    var start = 0
    while (start + pattern.size <= data.size) {
        var offset = 0
        while (offset < pattern.size && data[start + offset] == pattern[offset]) {
            offset += 1
        }
        if (offset == pattern.size) {
            return Some(Int64(start))
        }
        start += 1
    }
    None
}

/// Map a `path = "..."` value from `cjpm.toml` to a directory: absolute values are kept,
/// relative ones are resolved against the module root and a leading `./` is dropped.
func resolveDependencyDir(moduleRoot: String, declared: String): String {
    let trimmed = trimTrailingSeparators(declared)
    if (isAbsolutePath(trimmed)) {
        return trimmed
    }
    var rest = trimmed
    while (rest.startsWith("./") || rest.startsWith(".\\")) {
        rest = rest[2..rest.size]
    }
    moduleRoot + "/" + rest
}

/// Absolute in the POSIX sense (`/...`) or the Windows sense (`\...` or a `C:`/`c:` drive
/// prefix), so dependency discovery does not silently degrade on Windows.
func isAbsolutePath(path: String): Bool {
    if (path.startsWith("/") || path.startsWith("\\")) {
        return true
    }
    let bytes = path.toArray()
    bytes.size >= 2 && bytes[1] == 58 && isDrivePrefix(String.fromUtf8([bytes[0]])) // ':'
}

/// Append `<packageDir>/target/contract_meta` when that directory exists, deduplicating.
func appendExistingMetaDir(dirs: ArrayList<String>, packageDir: String): Unit {
    let candidate = trimTrailingSeparators(packageDir) + "/target/contract_meta"
    if (exists(candidate) && !dirs.contains(candidate)) {
        dirs.add(candidate)
    }
}

func trimTrailingSeparators(path: String): String {
    var trimmed = path
    while (trimmed.size > 1 && (trimmed.endsWith("/") || trimmed.endsWith("\\"))) {
        trimmed = trimmed[0..trimmed.size - 1]
    }
    trimmed
}

/// Whether `part` is a lone ASCII letter, i.e. a Windows drive prefix before `:`.
func isDrivePrefix(part: String): Bool {
    let bytes = part.toArray()
    bytes.size == 1 && (bytes[0] >= 0x41 && bytes[0] <= 0x5A || bytes[0] >= 0x61 && bytes[0] <= 0x7A)
}

/// Upper bound on any file read for metadata resolution (16 MiB). Contract records and
/// `cjpm.toml` files are orders of magnitude smaller, so the limit only catches a corrupt
/// or hostile file that would otherwise be loaded whole.
const _MAX_READ_FILE_BYTES: Int64 = 16 * 1024 * 1024

func readWholeFileSafe(path: String): ?Array<UInt8> {
    try {
        Some(readWholeFile(path))
    } catch (e: Exception) {
        None
    }
}

func readWholeFile(path: String): Array<UInt8> {
    // Records read here (`.cmeta` files and `cjpm.toml`) are small text files. Refuse an
    // implausibly large one instead of letting a corrupt or hostile file exhaust compiler
    // memory; the caller treats the failure like any other unreadable file.
    let size = FileInfo(Path(path)).size
    if (size > _MAX_READ_FILE_BYTES) {
        throw Exception("refusing to read ${path}: ${size} bytes exceeds the ${_MAX_READ_FILE_BYTES}-byte limit")
    }
    File.readFrom(Path(path))
}

// ---------------------------------------------------------------------------
// serialization
// ---------------------------------------------------------------------------

// FNV-1a 64-bit constants for the `.cmeta` content fingerprint.
const _FNV1A64_OFFSET_BASIS: UInt64 = 14695981039346656037
const _FNV1A64_PRIME: UInt64 = 1099511628211

/// One FNV-1a 64 round over a single byte. The multiply must wrap: Cangjie's default
/// integer semantics throw `OverflowException` and the very first round
/// (`offsetBasis * prime`) always overflows, which would make every `.cmeta` write fail
/// and every record read back as unreadable.
@OverflowWrapping
func fnv1a64Byte(hash: UInt64, byte: UInt8): UInt64 {
    (hash ^ UInt64(byte)) * _FNV1A64_PRIME
}

/// Fold one string into the hash: every UTF-8 byte participates, followed by a 0xFF
/// separator byte so that "ab"+"c" and "a"+"bc" cannot produce the same digest.
func fnv1a64Str(hash: UInt64, value: String): UInt64 {
    var result = hash
    for (byte in value.toArray()) {
        result = fnv1a64Byte(result, byte)
    }
    fnv1a64Byte(result, 0xFF)
}

/// Integers participate as their decimal string, so both the write side (in-memory field)
/// and the read side (parsed field) fold identical text.
func fnv1a64Int(hash: UInt64, value: Int64): UInt64 {
    fnv1a64Str(hash, value.toString())
}

/// FNV-1a 64-bit content fingerprint over every payload field of `data`, folded in exactly
/// the order `serializeMetaData` writes them. Token fields fold the exact source text stored
/// in the record (`tokensToSourceText` on the write side, the raw `str()` payload on the
/// read side) instead of a `tokensStableKey` of re-lexed tokens: re-lexing is only an
/// approximate round trip, while the stored text is byte-identical on both sides. The read
/// side in `parseMetaData` recomputes the same digest, so any change here must be mirrored
/// there in lockstep.
func metaDataFingerprint(data: ContractMetaData): UInt64 {
    var hash = fingerprintTypeHeader(_FNV1A64_OFFSET_BASIS, data)
    hash = fingerprintMemberSignatures(hash, data)
    hash = fingerprintClauses(hash, data)
    hash = fingerprintMemberAttrs(hash, data)
    hash = fingerprintPropertyAttrs(hash, data)
    fingerprintValueNames(hash, data)
}

/// Fold the record header fields up to the type contract tokens.
func fingerprintTypeHeader(hash: UInt64, data: ContractMetaData): UInt64 {
    var result = fnv1a64Int(hash, META_FORMAT_VERSION)
    result = fnv1a64Str(result, data.typeName)
    result = fnv1a64Str(result, data.packageName)
    result = fnv1a64Int(result, data.typeArgs.size)
    for (argument in data.typeArgs) {
        result = fnv1a64Str(result, argument)
    }
    result = fnv1a64Int(result, if (data.isInterface) {
        1
    } else {
        0
    })
    result = fnv1a64Int(result, if (data.isOpen) {
        1
    } else {
        0
    })
    result = fnv1a64Int(result, if (data.contracts.conforming) {
        1
    } else {
        0
    })
    fnv1a64Str(result, tokensToSourceText(data.contracts.tokens))
}

/// Fold the sorted member signature set.
func fingerprintMemberSignatures(hash: UInt64, data: ContractMetaData): UInt64 {
    // Same sorted iteration as the writer: a HashSet iterates in hash order, and the
    // fingerprint must be reproducible across processes.
    let memberSignatureList = ArrayList<String>()
    for (signature in data.allMemberSignatures) {
        memberSignatureList.add(signature)
    }
    memberSignatureList.sort()
    var result = fnv1a64Int(hash, memberSignatureList.size)
    for (signature in memberSignatureList) {
        result = fnv1a64Str(result, signature)
    }
    result
}

/// Fold the resolved clause list with its provenance.
func fingerprintClauses(hash: UInt64, data: ContractMetaData): UInt64 {
    var result = fnv1a64Int(hash, data.contracts.clauses.size)
    for (entry in data.contracts.clauses) {
        result = fnv1a64Str(result, entry.origin.declaringType)
        result = fnv1a64Int(result, entry.origin.clauseIndex)
        result = fnv1a64Int(result, entry.origin.typeArguments.size)
        for (argument in entry.origin.typeArguments) {
            // Same kind-then-text order as the writer and the reader: the kind marker is
            // payload too, and the fingerprint must be reproducible on both sides.
            result = fnv1a64Str(result, typeNodeKindMark(argument))
            result = fnv1a64Str(result, tokensToSourceText(argument.toTokens()))
        }
        result = fnv1a64Str(result, tokensToSourceText(metaClauseTokens(entry.clause)))
    }
    result
}

/// Fold the sorted member attribute map.
func fingerprintMemberAttrs(hash: UInt64, data: ContractMetaData): UInt64 {
    var result = fnv1a64Int(hash, data.memberAttrs.size)
    for (key in sortedKeys(data.memberAttrs)) {
        result = fnv1a64Str(result, key)
        result = hashAttrOrigins(result, data.memberAttrOrigins.get(key))
        result = fnv1a64Str(result, tokensToSourceText(data.memberAttrs.get(key).getOrThrow()))
        match (data.memberParamNames.get(key)) {
            case Some(names) =>
                result = fnv1a64Int(result, names.size)
                for (name in names) {
                    result = fnv1a64Str(result, name)
                }
            case None => result = fnv1a64Int(result, 0)
        }
        result = fnv1a64Str(result, data.memberCheckerBases.get(key) ?? "")
    }
    result
}

/// Fold the sorted property attribute map.
func fingerprintPropertyAttrs(hash: UInt64, data: ContractMetaData): UInt64 {
    var result = fnv1a64Int(hash, data.propertyAttrs.size)
    for (key in sortedKeys(data.propertyAttrs)) {
        result = fnv1a64Str(result, key)
        result = hashAttrOrigins(result, data.propertyAttrOrigins.get(key))
        result = fnv1a64Str(result, tokensToSourceText(data.propertyAttrs.get(key).getOrThrow()))
    }
    result
}

/// Fold the sorted value-name set.
func fingerprintValueNames(hash: UInt64, data: ContractMetaData): UInt64 {
    var result = fnv1a64Int(hash, data.valueNames.size)
    for (name in sortedStrings(data.valueNames)) {
        result = fnv1a64Str(result, name)
    }
    result
}

/// Fold the provenance map behind one attr key, mirroring `writeAttrOrigins` /
/// `readAttrOrigins`: a present map folds its size, then per sorted owner its name and its
/// sorted `kind|name` entries; an absent map folds `0`, exactly like the written count.
func hashAttrOrigins(hash: UInt64, origins: ?HashMap<String, HashSet<String>>): UInt64 {
    match (origins) {
        case Some(value) =>
            var result = fnv1a64Int(hash, value.size)
            let owners = ArrayList<String>()
            for (owner in value.keys()) {
                owners.add(owner)
            }
            owners.sort()
            for (owner in owners) {
                let names = ArrayList<String>()
                for (name in value.get(owner).getOrThrow()) {
                    names.add(name)
                }
                names.sort()
                result = fnv1a64Str(result, owner)
                result = fnv1a64Int(result, names.size)
                for (name in names) {
                    result = fnv1a64Str(result, name)
                }
            }
            result
        case None => fnv1a64Int(hash, 0)
    }
}

func serializeMetaData(data: ContractMetaData): Array<UInt8> {
    let writer = MetaWriter()
    writeMetaDataHeader(writer, data)
    writeMetaDataSignatures(writer, data)
    writeMetaDataClauses(writer, data)
    writeMetaDataMemberAttrs(writer, data)
    writeMetaDataPropertyAttrs(writer, data)
    writeMetaDataValueNames(writer, data)
    // Content fingerprint trailer: FNV-1a 64 over every payload field in exactly the write
    // order above, appended as 8 raw big-endian bytes. Because it is a fixed-size trailer,
    // a reader detects its absence (records written before fingerprints existed) simply by
    // the number of remaining bytes.
    writer.u64(metaDataFingerprint(data))
    writer.toBytes()
}

/// Write the magic, format version, and type header fields.
func writeMetaDataHeader(writer: MetaWriter, data: ContractMetaData): Unit {
    writer.word("CFGMETA")
    writer.int(META_FORMAT_VERSION)
    writer.word("TYPE")
    writer.str(data.typeName)
    writer.str(data.packageName)
    writer.int(data.typeArgs.size)
    for (argument in data.typeArgs) {
        writer.str(argument)
    }
    writer.flag(data.isInterface)
    writer.flag(data.isOpen)
    writer.flag(data.contracts.conforming)
    writer.tokens(data.contracts.tokens)
}

/// Write the sorted member signature set.
func writeMetaDataSignatures(writer: MetaWriter, data: ContractMetaData): Unit {
    writer.int(data.allMemberSignatures.size)
    // Sorted like the maps below: a HashSet iterates in hash order, and identical
    // records must serialize to identical bytes for dedupeIdenticalRecords to work.
    let memberSignatureList = ArrayList<String>()
    for (signature in data.allMemberSignatures) {
        memberSignatureList.add(signature)
    }
    memberSignatureList.sort()
    for (signature in memberSignatureList) {
        writer.str(signature)
    }
}

/// Write the resolved clause list with its provenance.
func writeMetaDataClauses(writer: MetaWriter, data: ContractMetaData): Unit {
    writer.int(data.contracts.clauses.size)
    for (entry in data.contracts.clauses) {
        writer.word("CLSE")
        writer.str(entry.origin.declaringType)
        writer.int(entry.origin.clauseIndex)
        writer.int(entry.origin.typeArguments.size)
        for (argument in entry.origin.typeArguments) {
            writer.word(typeNodeKindMark(argument))
            writer.tokens(argument.toTokens())
        }
        writer.tokens(metaClauseTokens(entry.clause))
    }
}

/// Write the sorted member attribute map with parameter names and checker bases.
func writeMetaDataMemberAttrs(writer: MetaWriter, data: ContractMetaData): Unit {
    // Write map entries in sorted-key order: identical records must serialize to
    // identical bytes regardless of hash-table iteration order, or dedupeIdenticalRecords
    // cannot recognize them as duplicates.
    writer.int(data.memberAttrs.size)
    let memberKeys = sortedKeys(data.memberAttrs)
    for (key in memberKeys) {
        writer.word("MATTR")
        writer.str(key)
        // `get` and not the subscript: on newer compilers a missing key throws instead of
        // yielding None, and absent origins are the common case for directly declared members.
        writeAttrOrigins(writer, data.memberAttrOrigins.get(key))
        writer.tokens(data.memberAttrs.get(key).getOrThrow())
        match (data.memberParamNames.get(key)) {
            case Some(names) =>
                writer.int(names.size)
                for (name in names) {
                    writer.str(name)
                }
            case None => writer.int(0)
        }
        writer.str(data.memberCheckerBases.get(key) ?? "")
    }
}

/// Write the sorted property attribute map.
func writeMetaDataPropertyAttrs(writer: MetaWriter, data: ContractMetaData): Unit {
    writer.int(data.propertyAttrs.size)
    let propertyKeys = sortedKeys(data.propertyAttrs)
    for (key in propertyKeys) {
        writer.word("PATTR")
        writer.str(key)
        writeAttrOrigins(writer, data.propertyAttrOrigins.get(key))
        writer.tokens(data.propertyAttrs.get(key).getOrThrow())
    }
}

/// Write the sorted value-name set.
func writeMetaDataValueNames(writer: MetaWriter, data: ContractMetaData): Unit {
    writer.int(data.valueNames.size)
    for (name in sortedStrings(data.valueNames)) {
        writer.str(name)
    }
}

/// Collect the map's keys in sorted order for deterministic serialization.
func sortedKeys(map: HashMap<String, Tokens>): ArrayList<String> {
    let keys = ArrayList<String>()
    for (key in map.keys()) {
        keys.add(key)
    }
    keys.sort()
    keys
}

/// Collect a string set in sorted order for deterministic serialization.
func sortedStrings(values: HashSet<String>): ArrayList<String> {
    let list = ArrayList<String>()
    for (value in values) {
        list.add(value)
    }
    list.sort()
    list
}

/// Provenance of one member's named contracts: declaring type -> `kind|name` set.
/// Owners and names are written in sorted order for deterministic output.
func writeAttrOrigins(writer: MetaWriter,
    origins: ?HashMap<String, HashSet<String>>): Unit {
    match (origins) {
        case Some(value) =>
            writer.int(value.size)
            let owners = ArrayList<String>()
            for (owner in value.keys()) {
                owners.add(owner)
            }
            owners.sort()
            for (owner in owners) {
                let names = ArrayList<String>()
                for (name in value.get(owner).getOrThrow()) {
                    names.add(name)
                }
                names.sort()
                writer.str(owner)
                writer.int(names.size)
                for (name in names) {
                    writer.str(name)
                }
            }
        case None => writer.int(0)
    }
}

/// Read one provenance map while folding the values into the running fingerprint; see
/// `hashAttrOrigins` for the write-side counterpart.
func readAttrOrigins(reader: MetaReader, hash: UInt64): (UInt64, HashMap<String, HashSet<String>>) {
    let result = HashMap<String, HashSet<String>>()
    var resultHash = hash
    let ownerCount = reader.int()
    resultHash = fnv1a64Int(resultHash, ownerCount)
    for (_ in 0..ownerCount) {
        let owner = reader.str()
        resultHash = fnv1a64Str(resultHash, owner)
        let pairCount = reader.int()
        resultHash = fnv1a64Int(resultHash, pairCount)
        let names = HashSet<String>()
        for (_ in 0..pairCount) {
            let name = reader.str()
            resultHash = fnv1a64Str(resultHash, name)
            names.add(name)
        }
        result.add(owner, names)
    }
    (resultHash, result)
}

/// Whether the stream starts with the expected magic and format header.
func readMetaMagic(reader: MetaReader): Bool {
    reader.word() == "CFGMETA" && reader.int() == META_FORMAT_VERSION && reader.word() == "TYPE"
}

/// Mutable state of one record read from a `.cmeta` stream. Each `read*` step consumes its
/// section and folds the same payload fields into the FNV-1a 64 digest the writer computed.
class MetaParseState {
    let name: String
    let reader: MetaReader
    var hash = _FNV1A64_OFFSET_BASIS
    var typeName = ""
    var packageName = ""
    let typeArgs = ArrayList<String>()
    var isInterface = false
    var isOpen = false
    var conforming = false
    var payload = Tokens()
    let signatures = HashSet<String>()
    var resolved: ?ResolvedTypeContract = None
    let memberAttrs = HashMap<String, Tokens>()
    let memberAttrOrigins = HashMap<String, HashMap<String, HashSet<String>>>()
    let memberParamNames = HashMap<String, ArrayList<String>>()
    let memberCheckerBases = HashMap<String, String>()
    let propertyAttrs = HashMap<String, Tokens>()
    let propertyAttrOrigins = HashMap<String, HashMap<String, HashSet<String>>>()
    let valueNames = HashSet<String>()

    init(name: String, reader: MetaReader) {
        this.name = name
        this.reader = reader
    }

    func readHeader(): Bool {
        this.hash = fnv1a64Int(this.hash, META_FORMAT_VERSION)
        this.typeName = this.reader.str()
        this.hash = fnv1a64Str(this.hash, this.typeName)
        this.packageName = this.reader.str()
        this.hash = fnv1a64Str(this.hash, this.packageName)
        let typeArgCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, typeArgCount)
        for (_ in 0..typeArgCount) {
            let argument = this.reader.str()
            this.hash = fnv1a64Str(this.hash, argument)
            this.typeArgs.add(argument)
        }
        this.isInterface = this.reader.int() == 1
        this.hash = fnv1a64Int(this.hash, if (this.isInterface) {
            1
        } else {
            0
        })
        this.isOpen = this.reader.int() == 1
        this.hash = fnv1a64Int(this.hash, if (this.isOpen) {
            1
        } else {
            0
        })
        this.conforming = this.reader.int() == 1
        this.hash = fnv1a64Int(this.hash, if (this.conforming) {
            1
        } else {
            0
        })
        // Token payloads are hashed as the raw stored text: re-lexing is only an
        // approximate round trip, so the digest must fold what was actually written.
        let payloadText = this.reader.tokensText()
        this.hash = fnv1a64Str(this.hash, payloadText)
        this.payload = cangjieLex(payloadText)
        true
    }

    func readSignatures(): Bool {
        let signatureCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, signatureCount)
        for (_ in 0..signatureCount) {
            let signature = this.reader.str()
            this.hash = fnv1a64Str(this.hash, signature)
            this.signatures.add(signature)
        }
        true
    }

    func readClauses(): Bool {
        let typeContract = ResolvedTypeContract(this.payload)
        typeContract.conforming = this.conforming
        let clauseCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, clauseCount)
        for (_ in 0..clauseCount) {
            if (!this.readClause(typeContract)) {
                return false
            }
        }
        this.resolved = Some(typeContract)
        true
    }

    func readClause(typeContract: ResolvedTypeContract): Bool {
        if (this.reader.word() != "CLSE") {
            reportUnreadableMeta(this.name)
            return false
        }
        let originType = this.reader.str()
        this.hash = fnv1a64Str(this.hash, originType)
        let originIndex = this.reader.int()
        this.hash = fnv1a64Int(this.hash, originIndex)
        let originArgCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, originArgCount)
        let originArguments = ArrayList<TypeNode>()
        for (_ in 0..originArgCount) {
            let argumentKind = this.reader.word()
            this.hash = fnv1a64Str(this.hash, argumentKind)
            let argumentText = this.reader.tokensText()
            this.hash = fnv1a64Str(this.hash, argumentText)
            originArguments.add(rebuildOriginTypeArgument(argumentKind, argumentText))
        }
        let clauseText = this.reader.tokensText()
        this.hash = fnv1a64Str(this.hash, clauseText)
        let parsed = parseClassContract(cangjieLex(clauseText))
        if (parsed.hasError() || parsed.value.clauses.isEmpty()) {
            var detail = if (parsed.value.clauses.isEmpty()) { "no clause produced" } else { "" }
            for (diagnostic in parsed.diagnostics) {
                detail = "${detail}; ${diagnostic.message}"
            }
            // Diagnostics must not carry tokens rebuilt from disk: `diagReport` rejects
            // token positions outside the current macro call range and would itself throw.
            diagReport(DiagReportLevel.WARNING, Tokens(),
                "contract metadata record for `${this.typeName}` could not be parsed (${detail}); cross-package inheritance from `${this.typeName}` is skipped",
                "the .cmeta record may be stale or written by an incompatible contract library version")
            return false
        }
        typeContract.add(ResolvedTypeClause(ClauseOrigin(originType, originIndex, originArguments),
            parsed.value.clauses[0]))
        true
    }

    func readMemberAttrs(): Bool {
        let memberAttrCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, memberAttrCount)
        for (_ in 0..memberAttrCount) {
            if (!this.readMemberAttr()) {
                return false
            }
        }
        true
    }

    func readMemberAttr(): Bool {
        if (this.reader.word() != "MATTR") {
            reportUnreadableMeta(this.name)
            return false
        }
        let key = this.reader.str()
        this.hash = fnv1a64Str(this.hash, key)
        let (originsHash, origins) = readAttrOrigins(this.reader, this.hash)
        this.hash = originsHash
        this.memberAttrOrigins.add(key, origins)
        let attrText = this.reader.tokensText()
        this.hash = fnv1a64Str(this.hash, attrText)
        this.memberAttrs.add(key, cangjieLex(attrText))
        let paramCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, paramCount)
        if (paramCount > 0) {
            let paramNames = ArrayList<String>()
            for (_ in 0..paramCount) {
                let paramName = this.reader.str()
                this.hash = fnv1a64Str(this.hash, paramName)
                paramNames.add(paramName)
            }
            this.memberParamNames.add(key, paramNames)
        }
        let checkerBase = this.reader.str()
        this.hash = fnv1a64Str(this.hash, checkerBase)
        if (checkerBase != "") {
            this.memberCheckerBases.add(key, checkerBase)
        }
        true
    }

    func readPropertyAttrs(): Bool {
        let propertyAttrCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, propertyAttrCount)
        for (_ in 0..propertyAttrCount) {
            if (!this.readPropertyAttr()) {
                return false
            }
        }
        true
    }

    func readPropertyAttr(): Bool {
        if (this.reader.word() != "PATTR") {
            reportUnreadableMeta(this.name)
            return false
        }
        let key = this.reader.str()
        this.hash = fnv1a64Str(this.hash, key)
        let (originsHash, origins) = readAttrOrigins(this.reader, this.hash)
        this.hash = originsHash
        this.propertyAttrOrigins.add(key, origins)
        let attrText = this.reader.tokensText()
        this.hash = fnv1a64Str(this.hash, attrText)
        this.propertyAttrs.add(key, cangjieLex(attrText))
        true
    }

    func readValueNames(): Bool {
        let valueNameCount = this.reader.int()
        this.hash = fnv1a64Int(this.hash, valueNameCount)
        for (_ in 0..valueNameCount) {
            let valueName = this.reader.str()
            this.hash = fnv1a64Str(this.hash, valueName)
            this.valueNames.add(valueName)
        }
        true
    }

    /// The record ends with the 8-byte content fingerprint written by `serializeMetaData`.
    /// Records written before fingerprints existed end right after the last payload field
    /// (only the final separator remains), so fewer than 8 remaining bytes mean "no
    /// fingerprint": such records are accepted as-is, which keeps old records readable.
    func checkFingerprint(): Unit {
        match (this.reader.tryReadU64()) {
            case Some(stored) =>
                if (stored != this.hash) {
                    reportStaleMetaRecord(this.typeName)
                }
            case None => ()
        }
    }

    func toMetaData(): ContractMetaData {
        ContractMetaData(this.typeName, this.typeArgs, this.resolved.getOrThrow(),
            isInterface: this.isInterface, isOpen: this.isOpen, memberAttrs: this.memberAttrs,
            propertyAttrs: this.propertyAttrs, memberAttrOrigins: this.memberAttrOrigins,
            propertyAttrOrigins: this.propertyAttrOrigins, allMemberSignatures: this.signatures,
            valueNames: this.valueNames, memberParamNames: this.memberParamNames,
            memberCheckerBases: this.memberCheckerBases, packageName: this.packageName)
    }
}

/// Parses one record; None (with a WARNING diagnostic) when the record cannot be rebuilt.
/// While reading, the payload fields are folded into the same FNV-1a 64 digest the writer
/// computed (`metaDataFingerprint`); a trailing fingerprint that does not match reports a
/// stale/corrupt record on stderr but still returns the parsed record, so compilation is
/// never interrupted by a mismatch alone.
func parseMetaData(name: String, data: Array<UInt8>): ?ContractMetaData {
    try {
        let reader = MetaReader(data)
        if (!readMetaMagic(reader)) {
            reportUnreadableMeta(name)
            return None
        }
        let state = MetaParseState(name, reader)
        if (!state.readHeader() || !state.readSignatures() || !state.readClauses() ||
            !state.readMemberAttrs() || !state.readPropertyAttrs() || !state.readValueNames()) {
            return None
        }
        // The record self-describes its type name (and package, when the build supplied one).
        // A record copied or renamed onto another type's file name must not be accepted:
        // inheriting it would silently attach a foreign contract to the requested type.
        let described = if (state.packageName == "") {
            state.typeName
        } else {
            state.packageName + "." + state.typeName
        }
        if (state.typeName != name && described != name) {
            diagReport(DiagReportLevel.WARNING, Tokens(),
                "contract metadata record for `${name}` describes `${described}` instead; cross-package inheritance from `${name}` is skipped",
                "delete the stale .cmeta file and rebuild the defining library")
            return None
        }
        state.checkFingerprint()
        Some(state.toMetaData())
    } catch (e: Exception) {
        diagReport(DiagReportLevel.WARNING, Tokens(),
            "contract metadata record for `${name}` is unreadable (${e.message}); cross-package inheritance from `${name}` is skipped",
            "delete the stale .cmeta file and rebuild the defining library")
        None
    }
}

/// Serialization marker for the concrete `TypeNode` kind of one origin type argument. The
/// `TypeNode` hierarchy has no runtime kind property, so the writer classifies by dynamic
/// type; the read side rebuilds a same-kind node because `RefType` throws on primitive text
/// and `PrimitiveType` on reference text. The marker participates in the content fingerprint
/// in the same kind-then-text order used by `serializeMetaData` and `parseMetaData`.
func typeNodeKindMark(node: TypeNode): String {
    match (node) {
        case _: RefType => "REF"
        case _: QualifiedType => "QUAL"
        case _: PrimitiveType => "PRIM"
        case _: ParenType => "PAREN"
        case _: TupleType => "TUPLE"
        case _: ThisType => "THIS"
        case _: PrefixType => "PREFIX"
        case _: FuncType => "FUNC"
        case _: VArrayType => "VARR"
        case _ => "REF"
    }
}

/// Build the node kind named by `kindMark`; None when the text does not parse as that kind.
func tryBuildTypedNode(kindMark: String, tokens: Tokens): ?TypeNode {
    try {
        match (kindMark) {
            case "PRIM" => return PrimitiveType(tokens)
            case "QUAL" => return QualifiedType(tokens)
            case "PAREN" => return ParenType(tokens)
            case "TUPLE" => return TupleType(tokens)
            case "THIS" => return ThisType(tokens)
            case "PREFIX" => return PrefixType(tokens)
            case "FUNC" => return FuncType(tokens)
            case "VARR" => return VArrayType(tokens)
            case _ => return RefType(tokens) // "REF" and unknown marks
        }
    } catch (e: Exception) {
        return None
    }
}

/// Rebuild one persisted origin type argument. A single argument that cannot be rebuilt as
/// a node must not invalidate the whole record: after the recorded kind and the two common
/// shapes fail, the raw text is carried as one `RefType` identifier so it still participates
/// in the downstream token substitution (every consumer only reads `toTokens()`). That last
/// resort cannot fail, which keeps the enclosing `parseMetaData` catch reserved for
/// structurally broken records.
func rebuildOriginTypeArgument(kindMark: String, text: String): TypeNode {
    let tokens = cangjieLex(text)
    match (tryBuildTypedNode(kindMark, tokens)) {
        case Some(node) => return node
        case None => ()
    }
    try {
        return RefType(tokens)
    } catch (e: Exception) {
        ()
    }
    try {
        return PrimitiveType(tokens)
    } catch (e: Exception) {
        ()
    }
    let carrier = RefType()
    carrier.identifier = Token(IDENTIFIER, text)
    return carrier
}

func reportUnreadableMeta(name: String): Unit {
    diagReport(DiagReportLevel.WARNING, Tokens(),
        "contract metadata record for `${name}` is unreadable or written by an incompatible contract library version; cross-package inheritance from `${name}` is skipped",
        "delete the stale .cmeta file and rebuild the defining library")
}

/// Best-effort line for a record whose trailing fingerprint does not match its
/// payload: the declaring library was rebuilt since the record was written, or the file is
/// corrupted. Deliberately not reported through `diagReport` and not fatal: the parent
/// library's sources may not be part of this build, so the parsed record is still returned.
/// Uses plain `println` (compiler-process stdout): macro plugins must not assume a
/// `Console` binding is available in every toolchain's `std.env`.
func reportStaleMetaRecord(typeName: String): Unit {
    println(
        "[stdx.contract] WARNING: stale or corrupt .cmeta record for ${typeName}; rebuild the declaring library")
}

/// Uniform access to a clause's source tokens across the `TypeClause` variants. Registered
/// metadata only ever contains `Invariant`/`Variable` entries (inherit kinds are expanded at
/// resolution time); the remaining cases are unreachable and yield an empty stream.
func metaClauseTokens(clause: TypeClause): Tokens {
    match (clause) {
        case Invariant(value) => value.tokens
        case Variable(value) => value.tokens
        case Inherits(_) => Tokens()
        case InvariantInherit(_) => Tokens()
    }
}

// ---------------------------------------------------------------------------
// token stream <-> source text (public std.ast surface only)
// ---------------------------------------------------------------------------

/// Text of `token` with an empty fallback: value-less tokens (e.g. EOF) throw
/// `NoneValueException` on `.value` in newer compilers instead of returning `""`.
func tokenText(token: Token): String {
    try {
        token.value
    } catch (e: Exception) {
        ""
    }
}

/// `(line, column)` of `token`, or `(-1, -1)` when the token carries no position. Positionless
/// tokens (e.g. synthesized during macro reconstruction) throw on `.pos` in newer compilers.
func tokenPosition(token: Token): (Int64, Int64) {
    try {
        (Int64(token.pos.line), Int64(token.pos.column))
    } catch (e: Exception) {
        (-1, -1)
    }
}

/// Whether `text` consists solely of operator/punctuation characters (no letters, digits,
/// underscore, or non-ASCII bytes). Such a token can re-lex together with a directly adjacent
/// neighbor into a different compound token (`>` `>` -> `>>`, `-` `-` -> `--`, `!` `=` -> `!=`).
func isOperatorText(text: String): Bool {
    for (byte in text.toArray()) {
        let isLetterOrDigit = (byte >= 48 && byte <= 57) || (byte >= 65 && byte <= 90) ||
            (byte >= 97 && byte <= 122) || byte == 95 || byte >= 128
        if (isLetterOrDigit) {
            return false
        }
    }
    text != ""
}

/// Rebuilds approximate source text from a token stream so the loader can re-lex it with
/// `cangjieLex`: tokens separated by whitespace in the source are re-separated the same way,
/// while tokens adjacent in the source are written back-to-back. The macro layer receives
/// compound operators (`>=`, `->`, ...) as separate adjacent character tokens (`>` `=`) with
/// authentic positions, so writing them back-to-back re-fuses them on re-lexing, exactly as
/// they appeared in the original source. Tokens whose adjacency cannot be proven — unknown
/// positions, or positions that contradict the running column (`column < prevEndColumn`,
/// which re-lexed token streams produce because `cangjieLex` restarts every token at the
/// same column) — are conservatively separated by a single space: that can never fuse two
/// tokens into one different token (`invariant` `true` -> `invarianttrue`, `>` `>` -> `>>`).
/// Only provably adjacent tokens are written back-to-back.
func tokensToSourceText(tokens: Tokens): String {
    let text = StringBuilder()
    var prevLine: Int64 = -1
    var prevEndColumn: Int64 = 0
    var prevValue = ""
    for (index in 0..tokens.size) {
        let token = tokens[index]
        if (token.kind == TokenKind.NL) {
            text.append("\n")
            prevLine = -1
            prevEndColumn = 0
            prevValue = ""
            continue
        }
        let value = tokenText(token)
        if (value == "") {
            continue
        }
        if (prevLine >= 0) {
            let (line, column) = tokenPosition(token)
            if (line < 0) {
                text.append(" ")
            } else if (line > prevLine) {
                text.append("\n")
            } else if (column > prevEndColumn) {
                text.append(" ")
            } else if (column == prevEndColumn) {
                // Adjacent in the original source: no separator, so re-lexing reproduces
                // the original token boundaries (including split compound operators).
            } else {
                // Overlapping or re-lexed positions: adjacency is unverifiable, so keep the
                // tokens apart (see the function comment).
                text.append(" ")
            }
        }
        text.append(value)
        let (line, column) = tokenPosition(token)
        prevLine = line
        prevEndColumn = column + value.size
        prevValue = value
    }
    text.toString()
}

// ---------------------------------------------------------------------------
// byte stream helpers
// ---------------------------------------------------------------------------

class MetaWriter {
    let buffer: ArrayList<UInt8> = ArrayList<UInt8>()

    func raw(text: String): Unit {
        for (byte in text.toArray()) {
            buffer.add(byte)
        }
    }

    func word(text: String): Unit {
        raw(text)
        buffer.add(32) // ' '
    }

    func int(value: Int64): Unit {
        word(value.toString())
    }

    func flag(value: Bool): Unit {
        word(if (value) {
            "1"
        } else {
            "0"
        })
    }

    /// `<len> <rawBytes> ` — the trailing separator is never part of the value.
    func str(value: String): Unit {
        let bytes = value.toArray()
        int(bytes.size)
        for (byte in bytes) {
            buffer.add(byte)
        }
        buffer.add(32)
    }

    func tokens(value: Tokens): Unit {
        word("TXT")
        str(tokensToSourceText(value))
    }

    /// Eight raw big-endian bytes of `value`, without any separator: the content
    /// fingerprint is a fixed-size trailer whose presence the reader detects by the
    /// number of remaining bytes.
    func u64(value: UInt64): Unit {
        buffer.add(UInt8((value >> 56) & 0xFF))
        buffer.add(UInt8((value >> 48) & 0xFF))
        buffer.add(UInt8((value >> 40) & 0xFF))
        buffer.add(UInt8((value >> 32) & 0xFF))
        buffer.add(UInt8((value >> 24) & 0xFF))
        buffer.add(UInt8((value >> 16) & 0xFF))
        buffer.add(UInt8((value >> 8) & 0xFF))
        buffer.add(UInt8(value & 0xFF))
    }

    func toBytes(): Array<UInt8> {
        buffer.toArray()
    }
}

class MetaFormatException <: Exception {
    public init() {
        super("malformed contract metadata stream")
    }

    public init(message: String) {
        super(message)
    }
}

class MetaReader {
    let data: Array<UInt8>
    var pos: Int64 = 0

    init(data: Array<UInt8>) {
        this.data = data
    }

    func skipSeparators(): Unit {
        while (pos < data.size && (data[pos] == 32 || data[pos] == 10 || data[pos] == 9)) {
            pos += 1
        }
    }

    /// Read one separator-delimited word.
    ///
    /// @throws MetaFormatException When the reader is at a separator or the end of the
    /// record, i.e. a word was expected but the record is truncated.
    func word(): String {
        skipSeparators()
        let start = pos
        while (pos < data.size && data[pos] != 32 && data[pos] != 10 && data[pos] != 9) {
            pos += 1
        }
        if (pos == start) {
            throw MetaFormatException()
        }
        String.fromUtf8(slice(start, pos))
    }

    /// Read one integer field.
    ///
    /// @throws MetaFormatException When the field is missing or is not a valid `Int64`.
    func int(): Int64 {
        let token = word()
        try {
            Int64.parse(token)
        } catch (e: Exception) {
            throw MetaFormatException("int parse failed at pos ${pos}: '${token}'")
        }
    }

    /// Read one length-prefixed string field.
    ///
    /// @throws MetaFormatException When the declared length is negative or exceeds the
    /// remaining record bytes.
    func str(): String {
        skipSeparators()
        let length = int()
        // Subtraction cannot overflow (pos <= data.size) while `pos + length` could wrap
        // around for a hostile length near Int64.Max, bypassing the bounds check. The
        // writer emits one separator byte between the length and the value, so the value
        // must still fit after that byte is consumed — accepting `length == remaining`
        // would overflow the slice below by one byte.
        if (length < 0 || length > data.size - pos - 1) {
            throw MetaFormatException("length out of range at pos ${pos}: ${length}")
        }
        // consume exactly the single separator the writer emitted after the length;
        // the value bytes themselves are never skipped
        if (pos < data.size && data[pos] == 32) {
            pos += 1
        }
        let value = String.fromUtf8(slice(pos, pos + length))
        pos += length
        value
    }

    /// Raw source text of a token payload, without lexing it: the content fingerprint
    /// folds this exact string, since re-lexing would only approximate the stored text.
    ///
    /// @throws MetaFormatException When the expected `TXT` marker is absent.
    func tokensText(): String {
        if (word() != "TXT") {
            throw MetaFormatException("TXT expected at pos ${pos}")
        }
        str()
    }

    /// Re-lexes the stored source text into real tokens. `cangjieLex` throws on malformed
    /// text; the caller's catch reports it as an unreadable record.
    func tokens(): Tokens {
        cangjieLex(tokensText())
    }

    /// Reads the 8-byte raw big-endian fingerprint trailer; `None` when fewer than 8 bytes
    /// remain, which is how records written without a fingerprint are recognized (they end
    /// right after the last payload field, with only the writer's final separator left).
    /// Only that single known separator may be consumed: `skipSeparators` would also eat a
    /// fingerprint whose first byte happens to be 0x20/0x0A/0x09 (~1.2% of records), making
    /// the trailer look absent and silently skipping the stale-record check.
    func tryReadU64(): ?UInt64 {
        if (pos < data.size && data[pos] == 32) {
            pos += 1
        }
        if (data.size - pos < 8) {
            return None
        }
        var value: UInt64 = 0
        for (index in 0..8) {
            value = (value << 8) | UInt64(data[pos + index])
        }
        pos += 8
        Some(value)
    }

    func slice(start: Int64, end: Int64): Array<UInt8> {
        let out = Array<UInt8>(end - start, repeat: 0)
        for (index in 0..end - start) {
            out[index] = data[start + index]
        }
        out
    }
}
