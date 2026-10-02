#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 中英文标点检查器，只报不改
# 中文句用全角标点，注释块结尾不加句末标点
# 反引号、「」、[Foo]、URL、TODO:、端口号、CSS 属性名不参与检查
# 单行加 punct-ignore 可豁免
import io
import os
import re
import sys
import json

CJK = u'一-鿿'
CJK_RE = re.compile(u'[%s]' % CJK)
NEAR = u'[%s，。、；：？！「」『』（）《》——…％\x00]' % CJK

C_EXT = ('.go', '.dart', '.ts', '.tsx', '.js', '.jsx', '.css', '.java', '.kt', '.swift', '.rs', '.c', '.h', '.cpp')
H_EXT = ('.yaml', '.yml', '.sh', '.bash', '.zsh', '.sql', '.py', '.toml')
SKIP_PART = ('/node_modules/', '/build/', '/dist/', '/.dart_tool/', '/vendor/',
             '/ent/', '/.git/', '/SourcePackages/', '/Pods/', '/.superpowers/')
SKIP_NAME = ('.g.dart', '.freezed.dart', '.pb.go', '_generated.go', 'schema.d.ts')

# 引述字面量与代码片段，一律不检查
PROTECT = re.compile(
    u'`[^`\n]*`'
    u'|「[^」\n]*」'
    u'|\\[[A-Za-z_][\\w.]*\\]'
    u'|https?://[^\\s，。；）)]+'
    u'|\\$\\{[^}\n]*\\}'
    u'|\\b(?:TODO|FIXME|HACK|NOTE|XXX)\\([^)\n]*\\)\\s*:'
    u'|^[ \t]*(?:TODO|FIXME|HACK|NOTE|XXX|[A-Za-z_][\\w.]*)[ \t]*:'
    u'|//[A-Za-z_]+:[A-Za-z_]+',
    re.M)

SCHEME = set(['dart', 'http', 'https', 'package', 'file', 'asset', 'mailto', 'tel'])
CSSPROP = set(['fill', 'stroke', 'flex', 'color', 'font', 'text', 'line', 'margin',
               'padding', 'width', 'height', 'top', 'right', 'bottom', 'left', 'display',
               'position', 'opacity', 'transform', 'content', 'gap', 'overflow', 'cursor',
               'order', 'size', 'background', 'border', 'grid', 'align', 'justify', 'clip',
               'filter', 'shadow', 'radius', 'offset', 'origin', 'visibility', 'zoom'])
MARK = re.compile(u'^(\\s*)(///+|//|/\\*+|\\*/|\\*|#+|--)?([ \t]*)(.*?)([ \t]*)$')
ID = re.compile(u'[A-Za-z0-9_]')


def comment_spans(text):
    # 扫描出注释区间，跳过字符串字面量（含 Dart 三引号与 raw string）
    spans = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in 'rR' and i + 1 < n and text[i + 1] in '\'"':
            i += 1
            continue
        if c in ('"', "'", '`'):
            if i + 2 < n and text[i + 1] == c and text[i + 2] == c:
                j = text.find(c * 3, i + 3)
                i = n if j < 0 else j + 3
                continue
            q = c
            i += 1
            while i < n:
                ch = text[i]
                if ch == '\\':
                    i += 2
                    continue
                if ch == q:
                    i += 1
                    break
                if ch == '\n' and q != '`':
                    break
                i += 1
            continue
        if c == '/' and i + 1 < n and text[i + 1] == '/':
            j = text.find('\n', i)
            j = n if j < 0 else j
            spans.append((i, j))
            i = j
            continue
        if c == '/' and i + 1 < n and text[i + 1] == '*':
            depth, j = 1, i + 2
            while j < n and depth:
                if text.startswith('/*', j):
                    depth += 1
                    j += 2
                elif text.startswith('*/', j):
                    depth -= 1
                    j += 2
                else:
                    j += 1
            spans.append((i, j))
            i = j
            continue
        i += 1
    return spans


def protect(s):
    keep = []

    def sub(m):
        keep.append(m.group(0))
        return u'\x00%d\x00' % (len(keep) - 1)
    return PROTECT.sub(sub, s), keep


def restore(s, keep):
    return re.sub(u'\x00(\\d+)\x00', lambda m: keep[int(m.group(1))], s)


def ctx(s):
    # 每个位置的括号深度与是否处在引号内
    depth, inq, q, out = 0, False, '', []
    for ch in s:
        if inq:
            out.append((depth, True))
            if ch == q:
                inq = False
            continue
        if ch in '\'"':
            inq, q = True, ch
            out.append((depth, True))
            continue
        if ch in '({[':
            out.append((depth, False))
            depth += 1
            continue
        if ch in ')}]':
            depth = max(0, depth - 1)
            out.append((depth, False))
            continue
        out.append((depth, False))
    return out


def fix_parens(s):
    # 括号内含中文，或中文紧邻左括号，取全角；函数调用与纯字符串参数不动
    stack, pairs = [], []
    c = ctx(s)
    for i, ch in enumerate(s):
        if c[i][1]:
            continue
        if ch == '(':
            stack.append(i)
        elif ch == ')' and stack:
            pairs.append((stack.pop(), i))
    out = list(s)
    for a, b in pairs:
        inner = s[a + 1:b]
        left = s[a - 1] if a > 0 else u' '
        if not CJK_RE.search(inner) and not re.match(u'[%s]' % CJK, left):
            continue
        if re.match(u'^\\s*[\'"].*[\'"]\\s*$', inner):
            continue
        if not CJK_RE.search(inner) and re.match(u'[A-Za-z0-9_)]', left):
            continue
        out[a], out[b] = u'（', u'）'
    return ''.join(out)


def word_left(s, i):
    j = i
    while j > 0 and re.match(u'[A-Za-z0-9_-]', s[j - 1]):
        j -= 1
    return s[j:i]


def normalize(body):
    # 返回符合规范的写法，与原文不同即为违规
    s, keep = protect(body)
    s = fix_parens(s)
    for half, full in ((u',', u'，'), (u';', u'；'), (u':', u'：')):
        tail = u'(?![0-9])' if half == u':' else u''
        s = re.sub(u'(?<=%s)[ \t]*%s[ \t]*%s' % (NEAR, re.escape(half), tail), full, s)
        s = re.sub(u'[ \t]*%s[ \t]*(?=%s)' % (re.escape(half), NEAR), full, s)
    for half, full in ((u'?', u'？'), (u'!', u'！')):
        s = re.sub(u'(?<=%s)%s' % (NEAR, re.escape(half)), full, s)
        s = re.sub(u'%s(?=%s)' % (re.escape(half), NEAR), full, s)
    s = re.sub(u'[ \t]+([，。、；：？！（）「」])', u'\\1', s)
    s = re.sub(u'([，。、；：？！（「])[ \t]+', u'\\1', s)
    # 英文词之间的半角标点：仅在两侧都是标识符且无空格时收全角
    c = ctx(s)
    out = list(s)
    for i, ch in enumerate(s):
        if ch not in ',;:' or c[i][1] or c[i][0] > 0:
            continue
        left = s[i - 1] if i > 0 else ''
        right = s[i + 1] if i + 1 < len(s) else ''
        if not (ID.match(left or ' ') and (ID.match(right or ' ') or CJK_RE.match(right or ' '))):
            continue
        lw = word_left(s, i)
        if '-' in lw:
            continue
        if ch == ':':
            if right == ':' or (i > 0 and s[i - 1] == ':'):
                continue
            if lw.lower() in SCHEME or lw.lower() in CSSPROP:
                continue
            if right.isdigit():
                continue
        out[i] = {',': u'，', ';': u'；', ':': u'：'}[ch]
    return restore(''.join(out), keep)


def merge_blocks(text, spans):
    blocks, cur = [], None
    for s, e in spans:
        is_line = text[s:s + 2] == '//'
        if cur and is_line and cur[2]:
            between = text[cur[1]:s]
            if between.strip() == '' and between.count('\n') == 1:
                cur = (cur[0], e, True)
                continue
        if cur:
            blocks.append(cur[:2])
        cur = (s, e, is_line)
    if cur:
        blocks.append(cur[:2])
    return blocks


def hash_blocks(lines):
    idx = [i for i, l in enumerate(lines) if re.match(r'^\s*(#|--)', l)]
    blocks, cur = [], []
    for i in idx:
        if cur and i == cur[-1] + 1:
            cur.append(i)
        else:
            if cur:
                blocks.append(cur)
            cur = [i]
    if cur:
        blocks.append(cur)
    return blocks


def scan_bodies(groups):
    # groups: [[(行号, 正文)]]，逐块检查，块尾另查句末标点
    hits = []
    for grp in groups:
        for k, (lineno, body) in enumerate(grp):
            if not CJK_RE.search(body) or 'punct-ignore' in body:
                continue
            nb = normalize(body)
            last = k == len(grp) - 1
            if last and nb and nb[-1] in u'。．':
                nb = nb[:-1]
            if nb != body:
                hits.append((lineno, body.strip(), nb.strip()))
    return hits


def check(path):
    ext = os.path.splitext(path)[1]
    norm = path.replace(os.sep, '/')
    if any(p in norm for p in SKIP_PART) or any(norm.endswith(s) for s in SKIP_NAME):
        return []
    try:
        text = io.open(path, encoding='utf-8').read()
    except Exception:
        return []
    lines = text.split('\n')
    hits = []
    if re.search(r'/\.github/workflows/[^/]+\.ya?ml$', norm):
        for i, l in enumerate(lines):
            if re.match(r'^\s*(- )?name:\s*.*', l) and CJK_RE.search(l.split('name:', 1)[-1]):
                hits.append((i + 1, l.strip(), u'工作流 name 用英文祈使短语'))
    if ext in C_EXT:
        groups = []
        for s, e in merge_blocks(text, comment_spans(text)):
            seg = text[s:e]
            if not CJK_RE.search(seg):
                continue
            start = text[:s].count('\n') + 1
            groups.append([(start + k, MARK.match(l).group(4)) for k, l in enumerate(seg.split('\n'))])
        hits += scan_bodies(groups)
    elif ext in H_EXT:
        groups = [[(i + 1, MARK.match(lines[i]).group(4)) for i in blk] for blk in hash_blocks(lines)]
        hits += scan_bodies(groups)
    return hits


def main():
    if len(sys.argv) < 2:
        return 0
    path = sys.argv[1]
    if not path or not os.path.isfile(path):
        return 0
    hits = check(path)
    if not hits:
        return 0
    rel = path
    msg = [u'%s 有 %d 处不符合标点规范：' % (rel, len(hits))]
    for lineno, old, new in hits[:20]:
        msg.append(u'  第 %d 行' % lineno)
        msg.append(u'    实际：%s' % old[:160])
        msg.append(u'    应为：%s' % new[:160])
    if len(hits) > 20:
        msg.append(u'  ……另有 %d 处' % (len(hits) - 20))
    msg.append(u'请修正后继续；确属引述字面量或代码片段的，在该行加 punct-ignore 豁免。')
    print(json.dumps({'decision': 'block', 'reason': '\n'.join(msg)}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
