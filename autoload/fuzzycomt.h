#include <Python.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

typedef struct
{ 
    PyObject *str;					// Python object with file path
    double  score;					// score of string
} returnstruct;

typedef struct
{
    char    *str_p;                 // pointer to string to be searched
    long    str_len;                // length of same
    char    *abbrev_p;              // pointer to search string (abbreviation)
    long    abbrev_len;             // length of same
    double  max_score_per_char;
    int     dot_file;               // boolean: true if str is a dot-file
} matchinfo_t;

returnstruct findmatch(PyObject* str, PyObject* abbrev, char *mmode);

void getLineMatches(PyObject* paths, PyObject* abbrev,returnstruct matches[], char *mode);

PyObject* fuzzycomt_match(PyObject* self, PyObject* args);
