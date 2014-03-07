import re

def from_vim(pat, ignorecase=False, smartcase=False):
    r"""
    Returns a pattern object based on the vim-style regular expression pattern string

    >>> from_vim('\w\+').pattern == '\w+'
    True
    >>> from_vim('foo\\').pattern == r'foo\\'
    True
    >>> from_vim('\w\+').flags
    0
    >>> from_vim('\c\w\+').flags
    2
    >>> from_vim('\C\w\+').flags
    0
    >>> from_vim('\C\w\+', ignorecase=True).flags
    0
    >>> from_vim('\w\+', ignorecase=True).flags
    2
    >>> from_vim('a', ignorecase=True, smartcase=True).flags
    2
    >>> from_vim('A', ignorecase=True, smartcase=True).flags
    0
    >>> from_vim('foo\=').pattern == 'foo?'
    True
    >>> from_vim('foo\?').pattern == 'foo?'
    True
    >>> from_vim('foo\{1,5}b').pattern == 'foo{1,5}b'
    True
    >>> from_vim('foo\{1,\}b').pattern == 'foo{1,}b'
    True
    >>> from_vim('foo\{-\}b').pattern == 'foo*?b'
    True
    >>> from_vim('foo\{-,1\}b').pattern == 'foo??b'
    True
    >>> from_vim('foo\{-1,\}b').pattern == 'foo+?b'
    True
    >>> from_vim('foo{1,}b').pattern == 'foo\{1,}b'
    True
    >>> from_vim('foo\>').pattern == r'foo\b'
    True
    >>> from_vim('\<foo').pattern == r'\bfoo'
    True
    >>> from_vim('\<foo\>').pattern == r'\bfoo\b'
    True
    >>> from_vim('foo\|bar').pattern == r'foo|bar'
    True
    >>> from_vim('\(foo\)').pattern == r'(foo)'
    True
    >>> from_vim('\(f(o)o\)').pattern == r'(f\(o\)o)'
    True
    >>> from_vim(r'\%(foo\)').pattern == r'(?:foo)'
    True
    >>> from_vim(r'\%(fo\(oba\)r\)').pattern == r'(?:fo(oba)r)'
    True
    >>> from_vim(r'foo\@=').pattern == r'fo(?=o)'
    True
    >>> from_vim('\(foo\)\@=').pattern == r'(?=foo)'
    True
    >>> from_vim(r'\%(foo\)\@=').pattern == r'(?=foo)'
    True
    >>> from_vim('foo\@!').pattern == r'fo(?!o)'
    True
    >>> from_vim('\(foo\)\@<=').pattern == r'(?<=foo)'
    True
    >>> from_vim(r'\%(foo\)\@<!').pattern == r'(?<!foo)'
    True
    >>> from_vim(r'[a-z]').pattern == r'[a-z]'
    True
    """

    flags = 0

    if pat.find("\c") != -1:
        pat = pat.replace("\c", "")
        flags |= re.IGNORECASE
    elif pat.find("\C") != -1:
        pat = pat.replace("\C", "")
    elif ignorecase:
        if smartcase:
            if not any(c.isupper() for c in pat):
                flags |= re.IGNORECASE
        else:
            flags |= re.IGNORECASE

    regex = process_group(pat)

    return re.compile(regex, flags)

def process_group(pat):
    special = False
    index = 0

    regex = r""
    incurly = False
    nongreedy = False
    nomemory = False

    skip = {}

    for char in pat:
        try:
            if skip[index]:
                index += 1
                continue
        except KeyError:
            pass

        if special:
            special = False

            if char == r'+':
                regex += char
            elif char == r'=' or char == r'?':
                regex += r'?'
            elif char == r'<' or char == r'>':
                regex += r'\b'
            elif char == r'|':
                regex += char
            elif char == r'{':
                if pat[index+1] == '-':
                    skip[index+1] = True

                    if non_greedy_skip(pat, index, skip):
                        regex += r'*?'
                    elif pat[index+2] == '1' and pat[index+3] == ',' and non_greedy_skip(pat, index + 2, skip):
                        skip.update(skip.fromkeys([index+2, index+3], True))
                        regex += r'+?'
                    elif pat[index+2] == ',' and pat[index+3] == '1' and non_greedy_skip(pat, index + 2, skip):
                        skip.update(skip.fromkeys([index+2, index+3], True))
                        regex += r'??'
                    else:
                        nongreedy = True
                else:
                    incurly = True
                    regex += r'{'

            elif char == r'%':
                if pat[index+1] == '(':
                    special = True
                    nomemory = True
            elif char == r'(':
                closing = find_matching(pat, index, r'\(', r'\)')

                regex += r'('
                if pat[closing+2:closing+5] == r'\@=':
                    regex += r'?='
                    skip.update(skip.fromkeys([closing+2, closing+3, closing+4], True))
                elif pat[closing+2:closing+5] == r'\@!':
                    regex += r'?!'
                    skip.update(skip.fromkeys([closing+2, closing+3, closing+4], True))
                elif pat[closing+2:closing+6] == r'\@<=':
                    regex += r'?<='
                    skip.update(skip.fromkeys([closing+2, closing+3, closing+4, closing+5], True))
                elif pat[closing+2:closing+6] == r'\@<!':
                    regex += r'?<!'
                    skip.update(skip.fromkeys([closing+2, closing+3, closing+4, closing+5], True))
                elif nomemory:
                    regex += r'?:'

                nomemory = False
            elif char == r')':
                regex += r')'
            elif char == r'@' and (pat[index+1] == '=' or pat[index+1] == '!' or pat[index+1] == '<'):
                atom = regex[-1]
                regex = regex[:-1] + r'('

                if pat[index+1] == '=':
                    regex += r'?='
                    skip[index+1] = True
                elif pat[index+1] == '!':
                    regex += r'?!'
                    skip[index+1] = True
                elif pat[index+2] == '=':
                    regex += r'?<='
                    skip.update(skip.fromkeys([index+1, index+2], True))
                elif pat[index+2] == '!':
                    regex += r'?<!'
                    skip.update(skip.fromkeys([index+1, index+2], True))

                regex += atom + r')'
            else:
                regex += '\\' + char
        elif char == '\\':
            if len(pat) == index + 1:
                regex += r'\\'
            elif pat[index+1] == '}'and incurly:
                special = False
            else:
                special = True
        else:
            if char == '{':
                regex += r'\{'
            elif char == '}' and incurly:
                incurly = False
                if nongreedy:
                    regex += r'}?'
                    nongreedy = False
                else:
                    regex += r'}'
            elif char == r'(':
                regex += r'\('
            elif char == r')':
                regex += r'\)'
            else:
                regex += char

        index += 1

    return regex

def find_matching(string, start, opening, closing):
    r"""
    Returns the index of the matching structure

    >>> find_matching("foo \( bar \) alpha", 5, "\(", "\)")
    11
    >>> find_matching("foo \( bar alpha", 5, "\(", "\)")
    -1
    >>> find_matching("foo \( bar \( inner 1 \) after \) alpha", 5, "\(", "\)")
    31
    >>> find_matching("foo \( bar \( in \( n \) er 1 \) after \) alpha", 5, "\(", "\)")
    39
    >>> find_matching("foo \( bar \( inner 1 \) after \) alpha \( another \( one \) no \) yes ", 5, "\(", "\)")
    31
    >>> find_matching("foo \( bar \( inner 1 after \) alpha", 5, "\(", "\)")
    28
    >>> find_matching(r"foo \( bar \\) inner 1 after \) alpha", 5, "\(", "\)")
    29
    """

    cursor = end = start - len(opening)

    while True:
        while end != -1:
            end = string.find(closing, end)
            if end != -1 and is_escaped(string, end):
                end += 1
            else:
                break

        while cursor != -1:
            cursor = string.find(opening, cursor)
            if cursor != -1 and is_escaped(string, cursor):
                cursor += 1
            else:
                break

        if not start:
            start = cursos

        if end < 0:
            end = string.rfind(closing)
            break

        next_cursor = cursor + 1
        while next_cursor != -1:
            next_cursor = string.find(opening, next_cursor)
            if next_cursor != -1 and is_escaped(string, next_cursor):
                next_cursor = next_cursor + 1
            else:
                break

        if cursor > -1 and next_cursor > -1 and next_cursor < end and cursor < end:
            cursor += 1
            end += 1
        else:
            break

    return end

def is_escaped(string, position):
    r"""
    Checks whether the entity at the given position is escaped

    >>> is_escaped(r"foo bar", 4)
    False
    >>> is_escaped(r"foo \\bar", 5)
    True
    >>> is_escaped(r"foo \\\\bar", 6)
    False
    >>> is_escaped(r"foo \\\\\\bar", 7)
    True
    """

    chars = list(string[:position])
    chars.reverse()

    counter = 0
    for c in chars:
        if c == '\\':
            counter += 1
        else:
            break

    return counter % 2 != 0

def non_greedy_skip(chars, index, skip):
    if chars[index+2] == '}':
        skip[index+2] = True
        return True
    elif chars[index+2] == '\\' and chars[index+3] == '}':
        skip[index+2] = True
        skip[index+3] = True
        return True
        skip[index+2] = True

    return False

if __name__ == "__main__":
    import doctest
    doctest.testmod()
