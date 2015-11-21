#!/bin/sh

if [ ! -f Makefile.PL -a -f ../Makefile.PL ]; then
    chdir ..
fi
if [ ! -f Makefile.PL ]; then
    echo wrong basedir, missing Makefile.PL
    exit
fi
if [ ! -d t/CORE ]; then
    if [ ! -d .git ]; then
        echo git clone p5-coretests.git t/CORE
        git clone https://github.com/perl11/p5-coretests.git t/CORE
    else
        if [ ! -f .gitmodules ]; then
            echo git submodule add p5-coretests.git t/CORE
            git submodule add https://github.com/perl11/p5-coretests.git t/CORE
        fi
        git submodule init
        echo git submodule update --remote
        git submodule update --remote
    fi
else
    git submodule init
    echo git submodule update --remote
    git submodule update --remote
fi
