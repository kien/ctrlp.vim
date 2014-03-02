from Queue import Empty, Queue
from threading import Thread

import re, os, vim

class CtrlP:
    def __init__(self):
        self.queue = Queue()
        self.lastPat = None

    def filter(self, items, pat, limit, exc, itemtype, mtype, ispath=False, byfname=False):
        processed = False
        if self.process():
            processed = True

        if self.lastPat == pat:
            if self.process() and self.queue.qsize() == 0 and not self.thread.isAlive():
                self.lastPat = None
            elif not processed:
                self.forceCursorHold()
        elif pat:
            self.thread = Thread(target=threadWorker, args=(
                self.queue, items, pat, limit, exc,
                itemtype, mtype, ispath, byfname, vim.eval('&ic'), vim.eval('&scs')
            ))
            self.thread.daemon = True
            self.thread.start()

            self.lastPat = pat
            self.forceCursorHold()

    def process(self):
        try:
            lines = self.queue.get(False)
            self.queue.task_done()

            callback = vim.bindeval('function("ctrlp#process")')
            lines = vim.List(lines)

            callback(lines, pat)

            return True
        except Empty:
            return False

    def forceCursorHold(self):
        vim.command("call feedkeys(\"f\e\")")

def threadWorker(queue, items, pat, limit, exc, itemtype, mtype, ispath, byfname, scs):
    patterns = splitPattern(pat, byfname, scs)

    id = 0
    matchedItems = []
    for item in items:
        id += 1
        if ispath and item == exc:
            continue

        if byfname:
            dirname = os.path.dirname(item)
            basename = os.path.basename(item)

            match = patterns[0].match(basename)

            if len(patterns) == 2 and match is not None:
                match = patterns[1].match(dirname)
        else:
            if itemtype > 2 and mtype == 'tabs':
                match = patterns[1].match(re.split('\t+', item)[0])
            elif itemtype > 2 and mtype == 'tabe':
                match = patterns[1].match(re.split('\t+[^\t]+$', item)[0])
            else:
                match = patterns[0].match(item)

        if match is None:
            continue

        matchedItems.append(item)

        if limit > 0 and len(matchedItems) >= limit:
            break

    queue.put(matchedItems, timeout=1)

def splitPattern(pat, byfname, ic, scs):
    chars =  [re.escape(c) for c in pat]

    patterns = []
    builder = lambda c: c + '[^' + c + ']*?'

    flags = 0
    if ic:
        if scs:
            upper = any(c.isupper() for c in pat)
            if upper:
                flags = re.I
        else:
            flags = re.I

    try:
        if byfname:
            delim = chars.index(';')
            filechars = chars[:delim]
            dirchars = chars[delim+1:]
            patterns.append(re.compile(''.join(map(builder, filechars)), flags))

            if dirchars:
                patterns.append(re.compile(''.join(map(builder, dirchars)), flags))
    finally:
        if not len(patterns):
            patterns.append(re.compile(''.join(map(builder, chars)), flags))

    return patterns
