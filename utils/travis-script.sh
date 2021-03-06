#! /usr/bin/env sh

set -v
set -e

export PATH=$INSTALL_DIR/bin:$PATH

# Log the toolchain to use
which gcc
which gprbuild
gcc -v
gprbuild -v

# Log which Langkit commit is used
(cd langkit && git log HEAD^..HEAD | cat)

# Avoid pretty-printing, for now: gnatpp from GNAT Community 2018 is known not
# to work on Libadalang.
ada/manage.py generate -P

# Build the Quex-generated lexer alone first, as it takes a huge amount of
# memory. Only then build the rest in parallel.
gprbuild -p -Pbuild/lib/gnat/libadalang.gpr \
    -XBUILD_MODE=dev -XLIBRARY_TYPE=relocatable -XXMLADA_BUILD=relocatable \
    -XLIBADALANG_WARNINGS=true -c -u libadalang_lexer.c
# Restrict parallelism to avoid OOM issues
ada/manage.py build -j12

# Finally, run the testsuite
ada/manage.py test -- -j16
