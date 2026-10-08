#!/usr/bin/env python3
"""Regenerates lib/moderation/text/confusables_table.g.dart.

Source data: Unicode UTS #39 `confusables.txt` (security/latest), downloaded
from https://www.unicode.org/Public/security/latest/confusables.txt.

We keep single-code-point sources and resolve their skeleton targets
transitively (UTS #39 defines the skeleton as repeated application) until the
target is pure ASCII letters/digits/spaces. Only these are useful for an
ASCII-latin matcher; multi-code-point sources and non-ASCII targets are
dropped. Sources already covered by the NFKD fold table are dropped here (the
normalizer consults the NFKD table first), which keeps the generated map
smaller and the precedence easy to reason about.

Run from the repository root:

    curl -sSLo /tmp/confusables.txt \
        https://www.unicode.org/Public/security/latest/confusables.txt
    python3 tool/moderation/generate_confusables_table.py /tmp/confusables.txt

The output is deterministic for a given confusables.txt revision.
"""

import re
import sys
import unicodedata
from pathlib import Path

TARGET = Path("apps/mobile-flutter/lib/moderation/text/confusables_table.g.dart")
MAX_CP = 0x30000


def fold(ch: str) -> str:
    s = unicodedata.normalize("NFKD", ch).casefold()
    return "".join(c for c in s if unicodedata.category(c) not in ("Mn", "Me"))


def nfkd_folded_codepoints() -> set[int]:
    out = set()
    for cp in range(MAX_CP):
        ch = chr(cp)
        if ch.isascii():
            continue
        s = fold(ch)
        if s and all(c.isascii() and (c.isalnum() or c == " ") for c in s):
            out.add(cp)
    return out


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    source = Path(sys.argv[1]).read_text(encoding="utf-8")

    raw: dict[int, list[int]] = {}
    for line in source.splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split(";")
        if len(parts) < 2:
            continue
        src = parts[0].strip().split()
        tgt = parts[1].strip().split()
        if len(src) != 1 or not tgt:
            continue
        try:
            src_cp = int(src[0], 16)
            tgt_cps = [int(t, 16) for t in tgt]
        except ValueError:
            continue
        raw.setdefault(src_cp, tgt_cps)

    nfkd = nfkd_folded_codepoints()

    def resolve(cp: int, depth: int = 0) -> str | None:
        """One code point to a candidate skeleton string, or None.

        A UTS #39 target may include combining overlays (`ł -> l + U+0338`).
        Those are stripped by the matcher, so the fallback folds a code point
        through NFKD when it has no (resolvable) entry of its own.
        """
        if depth > 12:
            return None
        if 0 <= cp < 0x80:
            return chr(cp)
        nxt = raw.get(cp)
        if nxt is not None:
            parts = [resolve(c, depth + 1) for c in nxt]
            if all(p is not None for p in parts):
                return "".join(p for p in parts if p is not None)
        folded = fold(chr(cp))
        if not folded and unicodedata.category(chr(cp)) in ("Mn", "Me"):
            # A combining mark that the matcher strips resolves to nothing.
            return ""
        if folded and all(c.isascii() and (c.isalnum() or c == " ") for c in folded):
            return folded
        return None

    # Only non-ASCII sources: ASCII sources in Confusables.txt encode leet
    # substitutions (1 -> l, 0 -> O, ...) and identifier-specific folds
    # (m -> rn). Folding those into *all* natural text mangles ordinary
    # digits and words; bounded leet-variant expansion on the wordlist side
    # handles substitution attacks instead.
    entries: dict[int, str] = {}
    for cp in sorted(raw):
        if cp < 0x80 or cp in nfkd:
            continue
        resolved = resolve(cp)
        if resolved is None or not resolved:
            continue
        s = "".join(c for c in resolved.casefold()
                    if unicodedata.category(c) not in ("Mn", "Me"))
        if not all(c.isascii() and (c.isalnum() or c == " ") for c in s):
            continue
        if s == chr(cp).casefold():
            continue
        entries[cp] = s

    lines = []
    lines.append("// GENERATED FILE - DO NOT EDIT BY HAND.")
    lines.append("//")
    lines.append(
        "// Derived from Unicode UTS #39 Confusables.txt (https://www.unicode.org/Public/security/latest/confusables.txt),"
    )
    lines.append("// © Unicode, Inc. Used under the Unicode License v3.")
    lines.append(
        "// Regenerate with tool/moderation/generate_confusables_table.py."
    )
    lines.append("//")
    lines.append(
        "// Single code point -> pure-ASCII skeleton, for scripts that the NFKD"
    )
    lines.append(
        "// fold table in unicode_fold_table.g.dart does not already merge."
    )
    lines.append("")
    lines.append("/// Cross-script lookalike skeleton (UTS #39, ASCII targets only).")
    lines.append("const Map<int, String> kConfusablesTable = <int, String>{")
    for cp in sorted(entries):
        escaped = entries[cp].replace("\\", "\\\\").replace("'", "\\'")
        lines.append(f"  0x{cp:X}: '{escaped}',")
    lines.append("};")
    lines.append("")

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {TARGET} with {len(entries)} entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
