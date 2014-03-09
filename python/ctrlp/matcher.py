from Queue import Empty, Queue
from threading import Thread
from ctrlp.regex import from_vim, is_escaped

import logging, re, os, tempfile

novim = False
try:
    import vim
except ImportError:
    novim = True

class CtrlPMatcher:
    def __init__(self, debug=False):
        if novim:
            raise ImportError("No module named vim")

        self.queue = Queue()
        self.patterns = []
        self.thread = None

        self.lastpat = None
        self.lastmmode = None
        self.lastispath = None
        self.lastregexp = None

        self.logger = logging.getLogger('ctrlp')
        hdlr = logging.FileHandler(os.path.join(tempfile.gettempdir(), 'ctrlp-py.log'))
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
        hdlr.setFormatter(formatter)
        self.logger.addHandler(hdlr)

        if debug:
            self.logger.setLevel(logging.DEBUG)

    def filter(self, items, pat, limit, mmode, ispath, crfile, regexp):
        if not pat:
            self.logger.debug("No pattern, returning original items")
            self.queue.put({"items": items[:limit], "subitems": items[limit-1:], "pat": ""}, timeout=1)

            self.process(pat)

            return

        self.logger.debug("Filtering {number} items using {pat}".format(number = len(items), pat=pat))

        self.process(pat)

        if self.lastpat == pat and self.lastmmode == mmode \
                and self.lastispath == ispath and self.lastregexp == regexp:
            if self.process(pat) and self.queue.qsize() == 0 and not self.thread.isAlive():
                self.logger.debug("Thread job is processed for {pat}".format(pat=pat))
                self.lastpat = None
            elif self.thread.isAlive() or self.queue.qsize() > 0:
                self.logger.debug("Waiting for thread job for {pat}".format(pat=pat))
                self.forceCursorHold()
            else:
                self.logger.debug("The same pattern '{pat}'".format(pat=pat))
        elif pat:
            self.logger.debug("Starting thread for {pat}".format(pat=pat))
            self.patterns.append(pat)

            mru = vim.bindeval('ctrlp#mrufiles#list()')
            mru = list(mru)[:50] if isinstance(mru, vim.List) else []

            self.thread = Thread(target=thread_worker, args=(
                self.queue, items, pat, limit,
                mmode, ispath, crfile, regexp, mru,
                vim.bindeval('&ic'), vim.bindeval('&scs'), self.logger
            ))
            self.thread.daemon = True
            self.thread.start()

            self.lastpat = pat
            self.lastmmode = mmode
            self.lastispath = ispath
            self.lastregexp = regexp

            self.forceCursorHold()

    def process(self, pat):
        queue = []
        while True:
            try:
                queue.append(self.queue.get(False))
                self.queue.task_done()
            except Empty:
                break

        if not queue:
            self.logger.debug("Empty queue")
            return False

        data = None

        for d in queue:
            if d["pat"]:
                try:
                    index = self.patterns.index(d["pat"])
                    self.patterns = self.patterns[index+1:]
                    data = d
                except ValueError:
                    continue
            else:
                data = d
                self.lastpat = None
                self.patterns = []
                break

        if not data:
            self.logger.debug("No valid data entry")
            return False

        callback = vim.bindeval('function("ctrlp#process")')
        lines = vim.List(data["items"])
        subitems = vim.List(data["subitems"])

        callback(lines, pat, 1, subitems)

        if data["pat"] == pat:
            self.queue = Queue()

        return True

    def forceCursorHold(self):
        vim.bindeval('function("ctrlp#forcecursorhold")')()


def thread_worker(queue, items, pat, limit, mmode, ispath, crfile, regexp, mru, ic, scs, logger):
    if ispath and mmode == 'filename-only':
        semi = 0
        while semi != -1:
            semi = pat.find(';', semi)
            if semi != -1 and is_escaped(pat, semi):
                semi += 1
            else:
                break
    else:
        semi = -1

    if semi != -1:
        pats = [pat[:semi], pat[semi+1:]] if pat[semi+1:] else [pat[:semi]]
    else:
        pats = [pat]

    patterns = []
    if regexp:
        logger.debug("Regex matching")
        patterns = [from_vim(p, ignorecase=ic, smartcase=scs) for p in pats]
    else:
        logger.debug("Fuzzy matching")
        flags = 0
        if ic:
            if scs:
                upper = any(c.isupper() for c in pat)
                if not upper:
                    flags = re.I
            else:
                flags = re.I

        for p in pats:
            chars = [re.escape(c) for c in p]
            builder = lambda c: c + '[^' + c + ']*?'

            patterns.append(re.compile(''.join(map(builder, chars)), flags))

    fileId = 0
    count = 0
    index = -1
    matchedItems = []
    skip = {}

    logger.debug("Matching against {number} items using {pat}".format(number=len(items), pat=pat))

    if ispath and (mmode == 'filename-only' or mmode == 'full-line'):
        for item in items:
            index += 1
            fileId += 1

            if item == crfile:
                continue

            basename = os.path.basename(item)
            span = ()
            match = None

            if mmode == 'filename-only':
                match = patterns[0].search(basename)
                if match:
                    span = match.span()

                    if len(patterns) == 2:
                        dirname = os.path.dirname(item)
                        match = patterns[1].search(dirname)

            elif mmode == 'full-line':
                match = patterns[0].search(basename)

            if not match:
                continue

            if not span:
                span = match.span()

            matchedItems.append({"line": item, "matlen": span[1] - span[0]})
            skip[index] = True

            if limit and count >= limit:
                break

            count += 1

    index = -1
    itemId = 0

    if count < limit - 1 and (not ispath or mmode != 'filename-only'):
        for item in items:
            index += 1
            itemId += 1

            if skip.get(index, False) or ispath and item == crfile:
                continue

            if mmode == 'first-non-tab':
                match = patterns[0].search(re.split('\t+', item)[0])
            elif mmode == 'until-last-tab':
                match = patterns[0].search(re.split('\t+[^\t]+$', item)[0])
            else:
                match = patterns[0].search(item)

            if match is None:
                continue

            span = match.span()
            matchedItems.append({"line": item, "matlen": span[1] - span[0]})

            if limit and count >= limit:
                break

            count += 1

    mrudict = {}
    index = 0
    for f in mru:
        mrudict[f] = index
        index += 1

    matchedItems = sorted(matchedItems, cmp=sort_items(crfile, mmode, ispath,
        mrudict, len(matchedItems)))

    if limit:
        matchedItems = matchedItems[:limit]

    queue.put({
        "items": [i["line"] for i in matchedItems],
        "subitems": items[itemId if itemId > fileId else fileId:],
        "pat": pat
    }, timeout=1)
    logger.debug("Got {number} matched items using {pat}".format(number=len(matchedItems), pat=pat))

def sort_items(crfile, mmode, ispath, mrudict, total):
    crdir = os.path.dirname(crfile)

    def cmp_func(a, b):
        line1 = a["line"]
        line2 = b["line"]
        len1 = len(line1)
        len2 = len(line2)

        lanesort = 0 if len1 == len2 else 1 if len1 > len2 else -1

        len1 = a["matlen"]
        len2 = b["matlen"]

        patsort = 0 if len1 == len2 else 1 if len1 > len2 else -1

        if ispath:
            ms = []

            fnlen = 0
            mtime = 0
            pcomp = 0

            if total < 21:
                len1 = len(os.path.basename(line1))
                len2 = len(os.path.basename(line2))
                fnlen = 0 if len1 == len2 else 1 if len1 > len2 else -1

                if mmode == 'full-line':
                    try:
                        len1 = os.path.getmtime(line1)
                        len2 = os.path.getmtime(line2)
                        mtime = 0 if len1 == len2 else 1 if len1 > len2 else -1

                        dir1 = os.path.dirname(line1)
                        dir2 = os.path.dirname(line2)

                        if dir1.endswith(crdir) and not dir2.endswith(crdir):
                            pcomp = -1
                        elif dir2.endswith(crdir) and not dir1.endswith(crdir):
                            pcomp = 1

                    except OSError:
                        pass

            mrucomp = 0
            if mrudict:
                len1 = mrudict.get(line1, -1)
                len2 = mrudict.get(line2, -1)

                mrucomp = 0 if len1 == len2 else 1 if len1 == -1 else -1 if len2 == -1 \
                        else 1 if len1 > len2 else -1

            ms.extend([fnlen, mtime, pcomp, patsort, mrucomp])
            mp = [2 if ms[0] else 0]
            mp.append(1 + (mp[0] if mp[0] else 1) if ms[1] else 0)
            mp.append(1 + (mp[0] + mp[1] if mp[0] + mp[1] else 1) if ms[2] else 0)
            mp.append(1 + (mp[0] + mp[1] + mp[2] if mp[0] + mp[1] + mp[2] else 1) if ms[3] else 0)
            mp.append(1 + (mp[0] + mp[1] + mp[2] + mp[3] if mp[0] + mp[1] + mp[2] + mp[3] else 1) if ms[4] else 0)

            return lanesort + reduce(lambda x, y: x + y[0]*y[1], zip(ms, mp), 0)
        else:
            return lanesort + patsort * 2

    return cmp_func
