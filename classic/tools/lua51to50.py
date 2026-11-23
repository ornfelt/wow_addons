#!/usr/bin/env python3
# lua51to50.py - rewrite Lua 5.1 source (WoW 2.x / 3.x addons) as Lua 5.0 source (the WoW 1.12 client).
#
# Only the syntax 5.0 lacks is rewritten, in place, so the code keeps its shape, comments and line
# numbers (Lua errors in the client point at the same lines as in the 5.1 copy):
#   #x                -> __len(x)                (strings and tables)
#   a % b             -> __mod(a, b)             (5.1's modulo: a - floor(a / b) * b)
#   ... (in a body)   -> unpack(arg)             (5.0 vararg functions get "arg"; arg.n counts nils)
#   ... (main chunk)  -> SkadaAddonArgs()        (WoW 1.12 passes addon files nothing)
#   s:format(...)     -> string.format(s, ...)   (5.0 strings have no methods; string lib names only)
#   0x1F              -> 31                      (5.0's lexer has no hex numbers)
#   [==[ ... ]==]     -> "..." / -- comments     (5.0 has no long bracket levels; [[ nests in 5.0)
# and in the .xml files <Script file="dir\x.lua"/> -> <Include> of a generated dir\Load_classic.xml
# (1.12 loads no script from a sub dir of the XML's dir).
# The helpers (__len, __mod, unpack with i / j, select, string.match ...) come from the environment
# the files run in: with --env NAME every file starts with "setfenv(1, NAME) " on its first line.
#
# It also reports what 5.0 cannot run and needs a hand fix: functions with more than 32 upvalues,
# repeat-until conditions that use locals of the loop body, and "arg" names in vararg functions.
# A file that contains the marker "lua50: native" is already 5.0 and is left alone.
#
# Usage examples:
#   python lua51to50.py Addons/Skada --env SkadaEnv          # convert a dir in place (recursive)
#   python lua51to50.py Addons/Skada/Core/Core.lua --env SkadaEnv
#   python lua51to50.py --path Addons/Skada --check          # report only, change nothing
#   python lua51to50.py Addons/Skada --no-recursive          # only the dir's own .lua files
#   python lua51to50.py Addons/Skada --show-cmd              # print the equivalent command, run nothing
#   python lua51to50.py Addons/Skada --verbose               # list every rewrite

import argparse
import os
import re
import shlex
import sys

# --- colored prints ----------------------------------------------------------

if os.name == "nt":
    os.system("")  # enables ANSI escape codes in the Windows console

RESET = "\033[0m"


def print_ok(msg):
    print(f"\033[32m{msg}{RESET}")


def print_err(msg):
    print(f"\033[31m{msg}{RESET}")


def print_warn(msg):
    print(f"\033[33m{msg}{RESET}")


def print_info(msg):
    print(f"\033[36m{msg}{RESET}")


# --- constants ---------------------------------------------------------------

NATIVE_MARKER = "lua50: native"
MAX_UPVALUES_50 = 32
MAIN_CHUNK_VARARGS = "SkadaAddonArgs()"
BODY_VARARGS = "unpack(arg)"
LEN_HELPER = "__len"
MOD_HELPER = "__mod"

# string library functions called as methods (s:format()) in the 5.1 code
STRING_METHODS = {
    "byte", "char", "find", "format", "gmatch", "gsub", "len", "lower", "match", "rep", "reverse",
    "sub", "upper", "trim", "split",
}

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local",
    "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
}

# binary operator priorities (left, right), Lua 5.1 lparser.c
BINARY_PRIORITY = {
    "+": (6, 6), "-": (6, 6), "*": (7, 7), "/": (7, 7), "%": (7, 7), "^": (10, 9), "..": (5, 4),
    "==": (3, 3), "~=": (3, 3), "<": (3, 3), "<=": (3, 3), ">": (3, 3), ">=": (3, 3),
    "and": (2, 2), "or": (1, 1),
}
UNARY_PRIORITY = 8
SYMBOLS = ["...", "..", "==", "~=", "<=", ">=", "+", "-", "*", "/", "%", "^", "#", "<", ">", "=",
           "(", ")", "{", "}", "[", "]", ";", ":", ",", "."]


class LuaSyntaxError(Exception):
    pass


# --- tokenizer ---------------------------------------------------------------

class Token:
    __slots__ = ("kind", "text", "start", "end", "line")

    def __init__(self, kind, text, start, end, line):
        self.kind, self.text, self.start, self.end, self.line = kind, text, start, end, line

    def __repr__(self):
        return f"{self.kind}:{self.text!r}@{self.line}"


LONG_OPEN = re.compile(r"\[(=*)\[")
NAME_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
NUMBER_RE = re.compile(r"0[xX][0-9a-fA-F]+|(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?")


def tokenize(src):
    """Tokens and trivia (comments / long strings kept for the rewrites). Positions are char indices."""
    tokens, comments, longstrings = [], [], []
    i, n, line = 0, len(src), 1
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r\f\v":
            i += 1
            continue
        if src.startswith("--", i):
            m = LONG_OPEN.match(src, i + 2)
            if m:
                close = "]" + m.group(1) + "]"
                j = src.find(close, m.end())
                if j < 0:
                    raise LuaSyntaxError(f"line {line}: unfinished long comment")
                end = j + len(close)
                comments.append((i, end, m.group(1), m.end(), j))
                line += src.count("\n", i, end)
                i = end
            else:
                j = src.find("\n", i)
                i = n if j < 0 else j
            continue
        if c == "[":
            m = LONG_OPEN.match(src, i)
            if m:
                close = "]" + m.group(1) + "]"
                j = src.find(close, m.end())
                if j < 0:
                    raise LuaSyntaxError(f"line {line}: unfinished long string")
                end = j + len(close)
                tokens.append(Token("string", src[i:end], i, end, line))
                longstrings.append((i, end, m.group(1), m.end(), j))
                line += src.count("\n", i, end)
                i = end
                continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                elif src[j] == "\n":
                    raise LuaSyntaxError(f"line {line}: unfinished string")
                j += 1
            if j >= n:
                raise LuaSyntaxError(f"line {line}: unfinished string")
            tokens.append(Token("string", src[i:j + 1], i, j + 1, line))
            line += src.count("\n", i, j + 1)  # "\<newline>" continuations
            i = j + 1
            continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = NUMBER_RE.match(src, i)
            tokens.append(Token("number", m.group(0), i, m.end(), line))
            i = m.end()
            continue
        m = NAME_RE.match(src, i)
        if m:
            word = m.group(0)
            tokens.append(Token("keyword" if word in KEYWORDS else "name", word, i, m.end(), line))
            i = m.end()
            continue
        for sym in SYMBOLS:
            if src.startswith(sym, i):
                tokens.append(Token("op", sym, i, i + len(sym), line))
                i += len(sym)
                break
        else:
            raise LuaSyntaxError(f"line {line}: unexpected character {c!r}")
    tokens.append(Token("eof", "", n, n, line))
    return tokens, comments, longstrings


# --- edits -------------------------------------------------------------------

class Edits:
    """Text edits on the original source: replacements of spans plus insertions before / after positions.
    Insertions at a position: the texts that close something (after) come before the texts that open
    something (before); an opening text added later wraps the earlier ones (outer expression)."""

    def __init__(self):
        self.replace = {}  # start -> (end, text)
        self.before = {}   # pos -> [texts], outermost first
        self.after = {}    # pos -> [texts], innermost first
        self.count = {}

    def note(self, what):
        self.count[what] = self.count.get(what, 0) + 1

    def sub(self, start, end, text):
        if start in self.replace and self.replace[start] != (end, text):
            raise LuaSyntaxError(f"overlapping rewrites at {start}")
        self.replace[start] = (end, text)

    def open(self, pos, text):
        self.before.setdefault(pos, []).insert(0, text)

    def close(self, pos, text):
        self.after.setdefault(pos, []).append(text)

    def apply(self, src):
        out, i, n = [], 0, len(src)
        while i <= n:
            if i in self.after:
                out.extend(self.after[i])
            if i in self.before:
                out.extend(self.before[i])
            if i == n:
                break
            if i in self.replace:
                end, text = self.replace[i]
                out.append(text)
                # insertions inside a replaced span would be lost
                i = end
                continue
            out.append(src[i])
            i += 1
        return "".join(out)


# --- parser with scopes ------------------------------------------------------

class FuncState:
    def __init__(self, parent, vararg, line, main=False):
        self.parent = parent
        self.vararg = vararg
        self.main = main
        self.line = line
        self.blocks = [[]]
        self.upvalues = set()
        self.uses_varargs = False
        self.declares_arg = False

    def declare(self, name):
        self.blocks[-1].append(name)
        if name == "arg":
            self.declares_arg = True

    def find_local(self, name):
        for block in reversed(self.blocks):
            if name in block:
                return True
        return False


class Parser:
    def __init__(self, src, path):
        self.src = src
        self.path = path
        self.tokens, self.comments, self.longstrings = tokenize(src)
        self.pos = 0
        self.edits = Edits()
        self.warnings = []
        self.fs = None

    # token helpers
    @property
    def tok(self):
        return self.tokens[self.pos]

    def peek(self, k=1):
        return self.tokens[min(self.pos + k, len(self.tokens) - 1)]

    def next(self):
        t = self.tokens[self.pos]
        self.pos += 1
        return t

    def check(self, text):
        t = self.tok
        return t.kind in ("op", "keyword") and t.text == text

    def accept(self, text):
        if self.check(text):
            return self.next()
        return None

    def expect(self, text):
        if not self.check(text):
            raise LuaSyntaxError(f"line {self.tok.line}: '{text}' expected near {self.tok.text!r}")
        return self.next()

    def expect_name(self):
        t = self.tok
        if t.kind != "name":
            raise LuaSyntaxError(f"line {t.line}: name expected near {t.text!r}")
        return self.next()

    def warn(self, line, msg):
        self.warnings.append(f"{self.path}:{line}: {msg}")

    # scopes
    def open_func(self, vararg, line, main=False):
        self.fs = FuncState(self.fs, vararg, line, main)

    def close_func(self):
        fs = self.fs
        if len(fs.upvalues) > MAX_UPVALUES_50:
            self.warn(fs.line, f"function has {len(fs.upvalues)} upvalues (5.0 allows {MAX_UPVALUES_50})")
        if fs.uses_varargs and fs.declares_arg and not fs.main:
            self.warn(fs.line, "vararg function declares a local 'arg' (5.0's varargs table)")
        self.fs = fs.parent

    def reference(self, name):
        fs = self.fs
        if fs.find_local(name):
            return "local"
        if name == "arg" and fs.vararg and not fs.main:
            self.warn(self.tok.line, "vararg function uses an outer 'arg' (5.0's own 'arg' hides it)")
        chain = []
        f = fs
        while f is not None and not f.find_local(name):
            chain.append(f)
            f = f.parent
        if f is None:
            return "global"
        for g in chain:
            g.upvalues.add(name)
        return "upvalue"

    # blocks and statements
    def parse_chunk(self):
        self.open_func(True, 1, main=True)
        self.block()
        if self.tok.kind != "eof":
            raise LuaSyntaxError(f"line {self.tok.line}: unexpected {self.tok.text!r}")
        self.close_func()

    def block_follow(self):
        t = self.tok
        return t.kind == "eof" or (t.kind == "keyword" and t.text in ("else", "elseif", "end", "until"))

    def block(self, scope=True):
        if scope:
            self.fs.blocks.append([])
        while not self.block_follow():
            if self.check("return"):
                self.next()
                if not self.block_follow() and not self.check(";"):
                    self.explist()
                self.accept(";")
                break
            if self.check("break"):
                self.next()
                self.accept(";")
                continue
            self.statement()
            self.accept(";")
        if scope:
            self.fs.blocks.pop()

    def statement(self):
        t = self.tok
        if t.kind == "keyword":
            if t.text == "if":
                self.next()
                self.expr()
                self.expect("then")
                self.block()
                while self.check("elseif"):
                    self.next()
                    self.expr()
                    self.expect("then")
                    self.block()
                if self.accept("else"):
                    self.block()
                self.expect("end")
                return
            if t.text == "while":
                self.next()
                self.expr()
                self.expect("do")
                self.block()
                self.expect("end")
                return
            if t.text == "do":
                self.next()
                self.block()
                self.expect("end")
                return
            if t.text == "for":
                self.for_stat()
                return
            if t.text == "repeat":
                self.repeat_stat()
                return
            if t.text == "function":
                self.next()
                is_method = self.funcname()
                self.funcbody(t.line, is_method)
                return
            if t.text == "local":
                self.next()
                if self.accept("function"):
                    name = self.expect_name()
                    self.fs.declare(name.text)
                    self.funcbody(t.line, False)
                else:
                    names = [self.expect_name().text]
                    while self.accept(","):
                        names.append(self.expect_name().text)
                    if self.accept("="):
                        self.explist()
                    for nm in names:
                        self.fs.declare(nm)
                return
        self.expr_stat()

    def for_stat(self):
        line = self.next().line
        first = self.expect_name().text
        if self.accept("="):
            self.expr()
            self.expect(",")
            self.expr()
            if self.accept(","):
                self.expr()
            names = [first]
        else:
            names = [first]
            while self.accept(","):
                names.append(self.expect_name().text)
            self.expect("in")
            self.explist()
        self.expect("do")
        self.fs.blocks.append(list(names))
        self.block()
        self.fs.blocks.pop()
        self.expect("end")

    def repeat_stat(self):
        line = self.next().line
        self.fs.blocks.append([])
        self.block(scope=False)
        self.expect("until")
        body_locals = set(self.fs.blocks[-1])
        start = self.pos
        self.expr()
        # 5.0's until does not see the body's locals (5.1's does)
        used = {self.tokens[k].text for k in range(start, self.pos) if self.tokens[k].kind == "name"}
        clash = sorted(used & body_locals)
        if clash:
            self.warn(line, f"repeat-until uses body locals {clash} (not visible to 5.0's until)")
        self.fs.blocks.pop()

    def funcname(self):
        name = self.expect_name()
        self.reference(name.text)
        while self.accept("."):
            self.expect_name()
        if self.accept(":"):
            self.expect_name()
            return True
        return False

    def funcbody(self, line, is_method):
        self.expect("(")
        params, vararg = [], False
        if not self.check(")"):
            while True:
                if self.accept("..."):
                    vararg = True
                    break
                params.append(self.expect_name().text)
                if not self.accept(","):
                    break
        self.expect(")")
        self.open_func(vararg, line)
        if is_method:
            self.fs.declare("self")
        for p in params:
            self.fs.declare(p)
        self.block(scope=False)
        self.expect("end")
        self.close_func()

    def expr_stat(self):
        _, _, kind = self.suffixedexp()
        if self.check("=") or self.check(","):
            while self.accept(","):
                self.suffixedexp()
            self.expect("=")
            self.explist()
        elif kind != "call":
            raise LuaSyntaxError(f"line {self.tok.line}: syntax error near {self.tok.text!r}")

    def explist(self):
        self.expr()
        while self.accept(","):
            self.expr()

    # expressions: each returns (start, end) of the expression's text
    def expr(self, limit=0):
        t = self.tok
        if (t.kind == "keyword" and t.text == "not") or (t.kind == "op" and t.text in ("-", "#")):
            op = self.next()
            ostart, oend = self.expr(UNARY_PRIORITY)
            if op.text == "#":
                self.edits.sub(op.start, op.end, LEN_HELPER + "(")
                self.edits.close(oend, ")")
                self.edits.note("#")
            start, end = op.start, oend
        else:
            start, end = self.simpleexp()
        while True:
            t = self.tok
            if not (t.kind in ("op", "keyword") and t.text in BINARY_PRIORITY):
                break
            left, right = BINARY_PRIORITY[t.text]
            if left <= limit:
                break
            op = self.next()
            _, rend = self.expr(right)
            if op.text == "%":
                self.edits.open(start, MOD_HELPER + "(")
                self.edits.sub(op.start, op.end, ",")
                self.edits.close(rend, ")")
                self.edits.note("%")
            end = rend
        return start, end

    def simpleexp(self):
        t = self.tok
        if t.kind == "number":
            self.next()
            if t.text[:2] in ("0x", "0X"):
                self.edits.sub(t.start, t.end, str(int(t.text, 16)))
                self.edits.note("hex")
            return t.start, t.end
        if t.kind == "string":
            self.next()
            return t.start, t.end
        if t.kind == "keyword" and t.text in ("nil", "true", "false"):
            self.next()
            return t.start, t.end
        if t.kind == "op" and t.text == "...":
            self.next()
            self.varargs(t)
            return t.start, t.end
        if t.kind == "op" and t.text == "{":
            return self.constructor()
        if t.kind == "keyword" and t.text == "function":
            self.next()
            start = t.start
            self.funcbody(t.line, False)
            return start, self.tokens[self.pos - 1].end
        start, end, _ = self.suffixedexp()
        return start, end

    def varargs(self, t):
        fs = self.fs
        if fs.main:
            self.edits.sub(t.start, t.end, MAIN_CHUNK_VARARGS)
            self.edits.note("... (main chunk)")
        elif fs.vararg:
            fs.uses_varargs = True
            self.edits.sub(t.start, t.end, BODY_VARARGS)
            self.edits.note("...")
        else:
            raise LuaSyntaxError(f"line {t.line}: '...' outside a vararg function")

    def primaryexp(self):
        t = self.tok
        if t.kind == "name":
            self.next()
            self.reference(t.text)
            return t.start, t.end
        if self.check("("):
            self.next()
            self.expr()
            close = self.expect(")")
            return t.start, close.end
        raise LuaSyntaxError(f"line {t.line}: unexpected symbol near {t.text!r}")

    def suffixedexp(self):
        start, end = self.primaryexp()
        kind = "var"
        while True:
            t = self.tok
            if self.check("."):
                self.next()
                end = self.expect_name().end
                kind = "var"
            elif self.check("["):
                self.next()
                self.expr()
                end = self.expect("]").end
                kind = "var"
            elif self.check(":"):
                colon = self.next()
                name = self.expect_name()
                if name.text in STRING_METHODS:
                    self.string_method(start, colon, name)
                end = self.callargs()
                kind = "call"
            elif self.check("(") or self.check("{") or t.kind == "string":
                end = self.callargs()
                kind = "call"
            else:
                return start, end, kind

    def string_method(self, start, colon, name):
        """expr:name(args) -> string.name(expr, args); expr:name"s" / expr:name{t} are rare enough to refuse."""
        t = self.tok
        if not self.check("("):
            raise LuaSyntaxError(f"line {t.line}: string method call without parentheses")
        empty = self.peek().kind == "op" and self.peek().text == ")"
        self.edits.open(start, f"string.{name.text}(")
        # ":name(" becomes ", " (or nothing for no arguments); the ")" stays
        self.edits.sub(colon.start, t.end, "" if empty else ", ")
        self.edits.note(f":{name.text}()")

    def callargs(self):
        t = self.tok
        if t.kind == "string":
            self.next()
            return t.end
        if self.check("{"):
            return self.constructor()[1]
        self.expect("(")
        if not self.check(")"):
            self.explist()
        return self.expect(")").end

    def constructor(self):
        start = self.expect("{").start
        while not self.check("}"):
            if self.check("["):
                self.next()
                self.expr()
                self.expect("]")
                self.expect("=")
                self.expr()
            elif self.tok.kind == "name" and self.peek().kind == "op" and self.peek().text == "=":
                self.next()
                self.next()
                self.expr()
            else:
                self.expr()
            if not (self.accept(",") or self.accept(";")):
                break
        end = self.expect("}").end
        return start, end


# --- long strings and comments -----------------------------------------------

def quote_long_string(body):
    """A long string's contents as a quoted 5.0 string, keeping its line breaks ("\\<newline>")."""
    if body.startswith("\r\n"):
        body = body[2:]
    elif body.startswith("\n"):
        body = body[1:]
    out = ['"']
    for ch in body:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\0":
            out.append("\\0")
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def needs_rewrite(level, body):
    # 5.0 has only [[ ]] and nests [[ inside it
    return level != "" or "[[" in body or "]]" in body


def rewrite_long_brackets(src, parser):
    edits = parser.edits
    for start, end, level, body_start, body_end in parser.longstrings:
        body = src[body_start:body_end]
        if needs_rewrite(level, body):
            edits.sub(start, end, quote_long_string(body))
            edits.note("long string")
    for start, end, level, body_start, body_end in parser.comments:
        body = src[body_start:body_end]
        if needs_rewrite(level, body):
            # line comments, one per line, so the line numbers stay
            lines = src[start:end].split("\n")
            text = "\n".join("-- " + ln.replace("]]", "] ]") for ln in lines)
            edits.sub(start, end, text)
            edits.note("long comment")


# --- driver ------------------------------------------------------------------

def convert(src, path, env):
    parser = Parser(src, path)
    parser.parse_chunk()
    rewrite_long_brackets(src, parser)
    out = parser.edits.apply(src)
    if env:
        out = f"setfenv(1, {env}) " + out
    return out, parser.edits.count, parser.warnings


# 1.12 cannot load <Script file="dir\file.lua"/> from an XML file (same-dir scripts and sub-dir
# <Include>s load): each run of such scripts with the same dir becomes an <Include> of a generated
# XML in that dir that loads them by their bare names.
SUBDIR_SCRIPT = re.compile(r'^(\s*)<Script file="([^"]*[\\/][^"]*)"\s*/>\s*$')
GENERATED_XML = "Load_classic{}.xml"
BACKSLASH = "\\"
XML_HEADER = ('<Ui xmlns="http://www.blizzard.com/wow/ui/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
              'xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..' + BACKSLASH + 'FrameXML' + BACKSLASH + 'UI.xsd">\n'
              '\t<!-- generated by classic/tools/lua51to50.py: 1.12 loads no <Script> from a sub dir -->\n')


def split_script(file):
    file = file.replace("/", BACKSLASH)
    return file.rsplit(BACKSLASH, 1)


def fix_xml(path, check):
    with open(path, encoding="utf-8", newline="") as f:
        text = f.read()
    nl = "\r\n" if "\r\n" in text else "\n"
    lines = text.split(nl)
    out, i, made = [], 0, 0
    base = os.path.dirname(path)
    while i < len(lines):
        m = SUBDIR_SCRIPT.match(lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        indent, folder = m.group(1), split_script(m.group(2))[0]
        group = []
        while i < len(lines):
            m2 = SUBDIR_SCRIPT.match(lines[i])
            if not m2 or split_script(m2.group(2))[0] != folder:
                break
            group.append(split_script(m2.group(2))[1])
            i += 1
        folder_path = os.path.join(base, *folder.split(BACKSLASH))
        n = 1
        while not check and os.path.exists(os.path.join(folder_path, GENERATED_XML.format("" if n == 1 else n))):
            n += 1
        name = GENERATED_XML.format("" if n == 1 else n)
        if not check:
            with open(os.path.join(folder_path, name), "w", encoding="utf-8", newline="\n") as f:
                f.write(XML_HEADER + "".join(f'\t<Script file="{g}"/>\n' for g in group) + "</Ui>\n")
        out.append(f'{indent}<Include file="{folder}{BACKSLASH}{name}"/>')
        made += 1
    if made and not check:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(nl.join(out))
    return made


def xml_files(target, recursive):
    if os.path.isfile(target):
        return
    for root, _, files in os.walk(target) if recursive else [(target, None, os.listdir(target))]:
        for f in sorted(files):
            if f.lower().endswith(".xml") and not f.startswith("Load_classic"):
                yield os.path.join(root, f)


def lua_files(target, recursive):
    if os.path.isfile(target):
        yield target
        return
    if recursive:
        for root, _, files in os.walk(target):
            for f in sorted(files):
                if f.lower().endswith(".lua"):
                    yield os.path.join(root, f)
    else:
        for f in sorted(os.listdir(target)):
            if f.lower().endswith(".lua"):
                yield os.path.join(target, f)


def show_cmd(args):
    parts = ["python", sys.argv[0], args.target]
    if args.env:
        parts += ["--env", args.env]
    if args.check:
        parts.append("--check")
    if not args.recursive:
        parts.append("--no-recursive")
    if args.verbose:
        parts.append("--verbose")
    quote = (lambda s: "'" + s.replace("'", "''") + "'") if os.name == "nt" else shlex.quote
    print(" ".join(quote(p) if (" " in p or "'" in p) else p for p in parts))


def main():
    ap = argparse.ArgumentParser(description="Rewrite Lua 5.1 addon source as Lua 5.0 (WoW 1.12).")
    ap.add_argument("target_pos", nargs="?", help="dir or .lua file (positional)")
    ap.add_argument("--path", dest="target_opt", help="dir or .lua file")
    ap.add_argument("--env", help="environment table every file runs in (setfenv on line 1)")
    ap.add_argument("--check", action="store_true", help="report only, write nothing")
    ap.add_argument("--no-recursive", dest="recursive", action="store_false", help="no sub dirs")
    ap.add_argument("--verbose", action="store_true", help="per-file rewrite counts")
    ap.add_argument("--show-cmd", action="store_true", help="print the equivalent command, run nothing")
    args = ap.parse_args()
    args.target = args.target_opt or args.target_pos
    if not args.target:
        ap.error("a dir or .lua file is needed")
    if args.show_cmd:
        show_cmd(args)
        return 0

    totals, warnings, errors, changed = {}, [], 0, 0
    for path in lua_files(args.target, args.recursive):
        with open(path, "rb") as f:
            raw = f.read()
        bom = raw.startswith(b"\xef\xbb\xbf")
        src = raw[3:].decode("latin-1") if bom else raw.decode("latin-1")
        if NATIVE_MARKER in src or src.startswith("setfenv(1, "):
            continue
        try:
            out, counts, warns = convert(src, path, args.env)
        except LuaSyntaxError as e:
            print_err(f"{path}: {e}")
            errors += 1
            continue
        warnings += warns
        for k, v in counts.items():
            totals[k] = totals.get(k, 0) + v
        if args.verbose and counts:
            print_info(f"{path}: " + ", ".join(f"{k} x{v}" for k, v in sorted(counts.items())))
        if out != src and not args.check:
            with open(path, "wb") as f:
                f.write(out.encode("latin-1"))
            changed += 1

    xml_fixed = 0
    for path in list(xml_files(args.target, args.recursive)):
        xml_fixed += fix_xml(path, args.check)
    if xml_fixed:
        print_info(f"sub-dir <Script> runs turned into <Include>s: {xml_fixed}")

    for w in warnings:
        print_warn(w)
    print_info("rewrites: " + (", ".join(f"{k} x{v}" for k, v in sorted(totals.items())) or "none"))
    if errors:
        print_err(f"{errors} file(s) not converted")
        return 1
    if args.check:
        print_ok("check done, nothing written")
    else:
        print_ok(f"changed {changed} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
