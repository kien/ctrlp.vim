from distutils.core import setup, Extension

extSearch = Extension('fuzzycomt', ['fuzzycomt.c'], extra_compile_args=['-std=c99'])


setup (name = 'fuzzycomt',
       version = '0.1',
       description = 'Fuzzy search in strings',
       ext_modules = [extSearch])

