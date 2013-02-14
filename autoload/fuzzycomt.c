#include "fuzzycomt.h"

void getLineMatches(PyObject* paths, PyObject* abbrev,returnstruct matches[], char *mmode)
{
	// iterate over lines and get match score for every line
    for (long i = 0, max = PyList_Size(paths); i < max; i++)
    {
        PyObject* path = PyList_GetItem(paths, i);
        returnstruct match;
        match = findmatch(path, abbrev, mmode);
		matches[i] = match;
    }
}

char *slashsplit(char *line)
{
    char *pch, *linedup, *fname;
    linedup = strdup(line);
    pch = strtok(linedup, "/");

    while (pch != NULL)
    {
        fname = pch;
        pch = strtok(NULL, "/");
    }
    char *retval = strdup(fname);
    free(linedup);
   return retval; 
}

// comparison function for use with qsort
int comp_alpha(const void *a, const void *b)
{
    returnstruct a_val = *(returnstruct *)a;
    returnstruct b_val = *(returnstruct *)b;

    char *a_p = PyString_AsString(a_val.str);
    long a_len = PyString_Size(a_val.str);
    char *b_p = PyString_AsString(b_val.str);
    long b_len = PyString_Size(b_val.str);

    int order = 0;
    if (a_len > b_len)
    {
        order = strncmp(a_p, b_p, b_len);
        if (order == 0)
            order = 1; // shorter string (b) wins
    }
    else if (a_len < b_len)
    {
        order = strncmp(a_p, b_p, a_len);
        if (order == 0)
            order = -1; // shorter string (a) wins
    }
    else
        order = strncmp(a_p, b_p, a_len);
    return order;
}

int comp_score(const void *a, const void *b)
{
    returnstruct a_val = *(returnstruct *)a;
    returnstruct b_val = *(returnstruct *)b;
    double a_score = a_val.score;
    double b_score = b_val.score;
    if (a_score > b_score)
        return -1; // a scores higher, a should appear sooner
    else if (a_score < b_score)
        return 1;  // b scores higher, a should appear later
    else
        return comp_alpha(a, b);
}

double recursive_match(matchinfo_t *m,  // sharable meta-data
                       long str_idx,    // where in the path string to start
                       long abbrev_idx, // where in the search string to start
                       long last_idx,   // location of last matched character
                       double score)    // cumulative score so far
{
    double seen_score = 0;      // remember best score seen via recursion
    int dot_file_match = 0;     // true if abbrev matches a dot-file
    int dot_search = 0;         // true if searching for a dot

    for (long i = abbrev_idx; i < m->abbrev_len; i++)
    {
        char c = m->abbrev_p[i];
        if (c == '.')
            dot_search = 1;
        int found = 0;
        for (long j = str_idx; j < m->str_len; j++, str_idx++)
        {
            char d = m->str_p[j];
            if (d == '.')
            {
                if (j == 0 || m->str_p[j - 1] == '/')
                {
                    m->dot_file = 1;        // this is a dot-file
                    if (dot_search)         // and we are searching for a dot
                        dot_file_match = 1; // so this must be a match
                }
            }
            else if (d >= 'A' && d <= 'Z')
                d += 'a' - 'A'; // add 32 to downcase
            if (c == d)
            {
                found = 1;
                dot_search = 0;

                // calculate score
                double score_for_char = m->max_score_per_char;
                long distance = j - last_idx;
                if (distance > 1)
                {
                    double factor = 1.0;
                    char last = m->str_p[j - 1];
                    char curr = m->str_p[j]; // case matters, so get again
                    if (last == '/')
                        factor = 0.9;
                    else if (last == '-' ||
                            last == '_' ||
                            last == ' ' ||
                            (last >= '0' && last <= '9'))
                        factor = 0.8;
                    else if (last >= 'a' && last <= 'z' &&
                            curr >= 'A' && curr <= 'Z')
                        factor = 0.8;
                    else if (last == '.')
                        factor = 0.7;
                    else
                        // if no "special" chars behind char, factor diminishes
                        // as distance from last matched char increases
                        factor = (1.0 / distance) * 0.75;
                    score_for_char *= factor;
                }

                if (++j < m->str_len)
                {
                    // bump cursor one char to the right and
                    // use recursion to try and find a better match
                    double sub_score = recursive_match(m, j, i, last_idx, score);
                    if (sub_score > seen_score)
                        seen_score = sub_score;
                }

                score += score_for_char;
                last_idx = str_idx++;
                break;
            }
        }
        if (!found)
            return 0.0;
    }
    return (score > seen_score) ? score : seen_score;
}


PyObject* fuzzycomt_match(PyObject* self, PyObject* args)
{
    PyObject *paths, *abbrev, *returnlist;
    Py_ssize_t limit;
    char *mmode;
    if (!PyArg_ParseTuple(args, "OOns", &paths, &abbrev, &limit, &mmode)) {
		// TODO add normal exception handling
       return NULL;
    }
	returnlist = PyList_New(0);

	//TODO dont include active buffer path to return list ( maybe better to do it in python part)

	//TODO add exception handling
	returnstruct matches[PyList_Size(paths)];

	if ( PyString_Size(abbrev) == 0)
	{
		// if string is empty - just return first (:param limit) lines
		PyObject *initlist;
		initlist = PyList_GetSlice(paths,0,limit);
		return initlist;
	}
	else
	{
		// find matches and place them into matches array.
		getLineMatches(paths,abbrev, matches, mmode);

		// sort array of struct by struct.score key
		qsort(matches, PyList_Size(paths), sizeof(returnstruct),comp_score);
	}

	
    for (long i = 0, max = PyList_Size(paths); i < max ; i++)
    {
            if (i == limit)
                break;
			PyObject *container;
			container = PyDict_New();
            PyDict_SetItemString(container,"line",matches[i].str);
            PyDict_SetItemString(container,"value",PyFloat_FromDouble(matches[i].score));
            PyList_Append(returnlist,container);
            //Py_DECREF(container);
    }

	// delete matches array
	// Malloc was not used on line 123, free() will cause segfaults
	//free(matches);

    return returnlist;
}


returnstruct findmatch(PyObject* str,PyObject* abbrev, char *mmode)
{
	//TODO look over the algorithm
    returnstruct returnobj;

    matchinfo_t m;
    if (strcmp(mmode, "filename-only") == 0) {
        m.str_p = slashsplit(PyString_AsString(str));
        m.str_len = strlen(m.str_p);
    }
    else {
        m.str_p                 = PyString_AsString(str);
        m.str_len               = PyString_Size(str);
    }
    m.abbrev_p              = PyString_AsString(abbrev);
    m.abbrev_len            = PyString_Size(abbrev);
    m.max_score_per_char    = (1.0 / m.str_len + 1.0 / m.abbrev_len) / 2;
    m.dot_file              = 0;


    // calculate score
    double score = 1.0;
    if (m.abbrev_len == 0) // special case for zero-length search string
    {
            for (long i = 0; i < m.str_len; i++)
            {
                char c = m.str_p[i];
                if (c == '.' && (i == 0 || m.str_p[i - 1] == '/'))
                {
                    score = 0.0;
                    break;
                }
            }
    }
    else // normal case
        score = recursive_match(&m, 0, 0, 0, 0.0);

    if (strcmp(mmode, "filename-only") == 0) {
        free(m.str_p);
    }
	
    returnobj.str = str;
    returnobj.score = score;

    return returnobj;
}

static PyMethodDef fuzzycomt_funcs[] = {
    {"match",(PyCFunction)fuzzycomt_match,METH_NOARGS,NULL},
    { "match", fuzzycomt_match, METH_VARARGS, NULL },
    {NULL}
};

PyMODINIT_FUNC initfuzzycomt()
{
    Py_InitModule3("fuzzycomt", fuzzycomt_funcs,
                   "Fuzzy matching module");
}
