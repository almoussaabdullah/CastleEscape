#!/usr/bin/env python3
"""Light structural checks for Swift sources when no compiler is available.

Checks bracket balance (ignoring strings and comments), reports unbalanced files with the
line where the imbalance first goes negative, and flags a few known-bad SpriteKit/SwiftUI
API spellings.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

BAD_PATTERNS = [
    (r"\.moveBy\(x:\s*[^,\)]+,\s*duration:", "SKAction.moveBy needs x:y:duration:"),
    (r"SKAction\.speed\(\s*[^t]", "SKAction.speed(to:duration:) misuse"),
    (r"\.run\(\s*withKey", ".run(withKey:) misuse"),
    (r"UIColor\(red: [0-9.]+, green: [0-9.]+, blue: [0-9.]+\)", "UIColor needs alpha:"),
]


def strip_strings_and_comments(src: str) -> str:
    out = []
    i = 0
    n = len(src)
    in_block = 0
    while i < n:
        ch = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        if in_block:
            if ch == "/" and nxt == "*":
                in_block += 1
                i += 2
                continue
            if ch == "*" and nxt == "/":
                in_block -= 1
                i += 2
                continue
            out.append("\n" if ch == "\n" else " ")
            i += 1
            continue
        if ch == "/" and nxt == "/":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if ch == "/" and nxt == "*":
            in_block = 1
            i += 2
            continue
        if ch == '"':
            # multi-line string
            if src.startswith('"""', i):
                j = src.find('"""', i + 3)
                j = n if j < 0 else j + 3
                out.append("".join("\n" if c == "\n" else " " for c in src[i:j]))
                i = j
                continue
            j = i + 1
            depth = 0
            while j < n:
                c = src[j]
                if c == "\\":
                    if src[j + 1:j + 2] == "(":
                        depth += 1
                        j += 2
                        continue
                    j += 2
                    continue
                if depth:
                    if c == "(":
                        depth += 1
                    elif c == ")":
                        depth -= 1
                    j += 1
                    continue
                if c == '"':
                    j += 1
                    break
                if c == "\n":
                    break
                j += 1
            out.append(" " * (j - i))
            i = j
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def check(path):
    src = open(path, encoding="utf-8").read()
    clean = strip_strings_and_comments(src)
    problems = []
    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for line_no, line in enumerate(clean.split("\n"), 1):
        for ch in line:
            if ch in "([{":
                stack.append((ch, line_no))
            elif ch in ")]}":
                if not stack or stack[-1][0] != pairs[ch]:
                    problems.append(f"{path}:{line_no}: unexpected '{ch}'")
                    stack = stack[:-1] if stack else stack
                else:
                    stack.pop()
    for ch, line_no in stack:
        problems.append(f"{path}:{line_no}: unclosed '{ch}'")
    for pattern, message in BAD_PATTERNS:
        for m in re.finditer(pattern, src):
            line_no = src.count("\n", 0, m.start()) + 1
            problems.append(f"{path}:{line_no}: {message}")
    return problems


def main():
    problems = []
    count = 0
    for folder in ("CastleEscape", "CastleEscapeTests"):
        for dirpath, _, files in os.walk(os.path.join(ROOT, folder)):
            for name in files:
                if name.endswith(".swift"):
                    count += 1
                    problems.extend(check(os.path.join(dirpath, name)))
    print(f"checked {count} files")
    for p in problems:
        print(p)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
