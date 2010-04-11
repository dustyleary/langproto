#!/bin/bash
for f in $( ls ); do
    if [ -d $f ]
    then
        echo $f
        pushd $f >/dev/null
        mzscheme tests.ss
        v=$?
        popd >/dev/null
        if [ 0 -ne $v ] ; then
            exit $?
        fi
    fi
done

