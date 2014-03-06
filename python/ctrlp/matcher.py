from Queue import Empty, Queue
from threading import Thread

import logging, re, os, tempfile, vim

class CtrlPMatcher:
    def __init__(self, debug=False):
        self.queue = Queue()
        self.patterns = []
        self.lastPat = None

        self.logger = logging.getLogger('ctrlp')
        hdlr = logging.FileHandler(os.path.join(tempfile.gettempdir(), 'ctrlp-py.log'))
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
        hdlr.setFormatter(formatter)
        self.logger.addHandler(hdlr)

        if debug:
            self.logger.setLevel(logging.DEBUG)

    def filter(self, items, pat, limit, mmode, ispath, crfile, regexp):
        limit = int(limit) if limit else None
        if not pat:
            self.logger.debug("No pattern, returning original items")
            self.queue.put({"items": items[:limit], "subitems": items[limit-1:], "pat": ""}, timeout=1)

            self.process(pat)

            return

        self.logger.debug("Filtering {number} items using {pat}".format(number = len(items), pat=pat))

        self.process(pat)

        if self.lastPat == pat:
            if self.process(pat) and self.queue.qsize() == 0 and not self.thread.isAlive():
                self.logger.debug("Thread job is processed for {pat}".format(pat=pat))
                self.lastPat = None
            elif self.thread.isAlive() or self.queue.qsize() > 0:
                self.logger.debug("Waiting for thread job for {pat}".format(pat=pat))
                self.forceCursorHold()
            else:
                self.logger.debug("The same pattern '{pat}'".format(pat=pat))
        elif pat:
            self.logger.debug("Starting thread for {pat}".format(pat=pat))
            self.patterns.append(pat)
            self.thread = Thread(target=threadWorker, args=(
                self.queue, items, pat, limit,
                mmode, ispath, crfile, regexp,
                vim.eval('&ic'), vim.eval('&scs'), self.logger
            ))
            self.thread.daemon = True
            self.thread.start()

            self.lastPat = pat
            self.forceCursorHold()

    def process(self, pat):
        try:
            data = self.queue.get(False)
            self.queue.task_done()

            try:
                if data["pat"]:
                    index = self.patterns.index(data["pat"])
                    self.patterns = self.patterns[index+1:]
                else:
                    self.lastPat = None
                    self.patterns = []
            except ValueError:
                return False

            callback = vim.bindeval('function("ctrlp#process")')
            lines = vim.List(data["items"])
            subitems = vim.List(data["subitems"])

            callback(lines, pat, 1, subitems)

            if data["pat"] == pat:
                self.queue = Queue()

            return True
        except Empty:
            return False

    def forceCursorHold(self):
        vim.bindeval('function("ctrlp#forcecursorhold")')()


def threadWorker(queue, items, pat, limit, mmode, ispath, crfile, regexp, ic, scs, logger):
    chars =  [re.escape(c) for c in pat]

    patterns = []
    builder = lambda c: c + '[^' + c + ']*?'

    flags = 0
    if ic:
        if scs:
            upper = any(c.isupper() for c in pat)
            if not upper:
                flags = re.I
        else:
            flags = re.I

    try:
        if mmode == 'filename-only':
            delim = chars.index(';')
            logger.debug("Creating filename patterns")
            filechars = chars[:delim]
            dirchars = chars[delim+1:]
            patterns.append(re.compile(''.join(map(builder, filechars)), flags))

            if dirchars:
                patterns.append(re.compile(''.join(map(builder, dirchars)), flags))
    except ValueError:
        pass

    if not len(patterns):
        patterns.append(re.compile(''.join(map(builder, chars)), flags))
        logger.debug("Creating normal patterns")

    itemId = 0
    matchedItems = []
    logger.debug("Matching against {number} items using {pat}".format(number=len(items), pat=pat))
    for item in items:
        itemId += 1
        if ispath and item == crfile:
            continue

        if mmode == 'filename-only':
            dirname = os.path.dirname(item)
            basename = os.path.basename(item)

            match = patterns[0].search(basename)

            if len(patterns) == 2 and match is not None:
                match = patterns[1].search(dirname)
        elif mmode == 'first-non-tab':
            match = patterns[1].search(re.split('\t+', item)[0])
        elif mmode == 'until-last-tab':
            match = patterns[1].search(re.split('\t+[^\t]+$', item)[0])
        else:
            match = patterns[0].search(item)

        if match is None:
            continue

        span = match.span()
        matchedItems.append({"line": item, "matlen": span[1] - span[0]})

    matchedItems = sorted(matchedItems, cmp=sortItems(crfile, mmode, ispath, len(matchedItems)))
    if limit > 0:
        matchedItems = matchedItems[:limit]

    queue.put({"items": [i["line"] for i in matchedItems], "subitems": items[itemId:], "pat": pat}, timeout=1)
    logger.debug("Got {number} matched items using {pat}".format(number=len(matchedItems), pat=pat))

def sortItems(crfile, mmode, ispath, total):
    crdir = os.path.dirname(crfile)

    def cmpFunc(a, b):
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

            ms.extend([fnlen, mtime, pcomp, patsort])
            mp = [2 if ms[0] else 0]
            mp.append(1 + (mp[0] if mp[0] else 1) if ms[1] else 0)
            mp.append(1 + (mp[0] + mp[1] if mp[0] + mp[1] else 1) if ms[2] else 0)
            mp.append(1 + (mp[0] + mp[1] + mp[2] if mp[0] + mp[1] + mp[2] else 1) if ms[3] else 0)

            return lanesort + reduce(lambda x, y: x + y[0]*y[1], zip(ms, mp), 0)
        else:
            return lanesort + patsort * 2

    return cmpFunc
