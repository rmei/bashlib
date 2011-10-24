#!/bin/bash

#
# canonical <path> [varname]
#
#  Calculates the canonical path for the file/dir referenced by <path>,
# assigns this value to varname, and prints it to STDOUT. If varname begins
# with "-" then that character will be stripped from varname and the value
# will *not* be printed to STDOUT. If an error is encountered, nothing will
# be printed and varname will be unset.
#
function canonical {
    local l="$1" s this next r="$2" out="$3"
    if [ $# -lt 3 ]; then
        r="$1"
        [ -n "${r%%/*}" ] && r="$PWD/$r"
    fi
    r="$r/" ; r="${r//\/.\/}" ; r="${r%%/}" ; r="${r##/}"
    this="${r%%/*}"
    next="${r#$this}" ; next="${next##/}"
    if [ $# -eq 1 ]; then
        canonical "" "$r" CANONICAL_PATHNAME
    elif [ $# -eq 2 ]; then
        out="$2" ; [ "-" == "$out" ] && out="-CANONICAL_PATHNAME"
        canonical "" "$r" "$out"
    elif [ $# -eq 3 ]; then
        if [ -L "$l/$this" ]; then # dereference symlinks
            s=`readlink "$l/$this"`
            if [ -z "${s%%/*}" ]; then # it's absolute; restart
                canonical "${s%%/}/$next" $out
            elif [ -n "${s%%*/*}" ]; then # it's local; retry
                canonical "$l" "$s/$next" $out
            else # it's relative; insert and continue
                canonical "$l" "${s%%/}/$next" $out
            fi
        elif [ "$this" == "." ]; then canonical "$l" "$next" $out
        elif [ "$this" == ".." ]; then canonical "${l%/*}" "$next" $out
        elif [ -z "$r" ]; then # DONE
            s="$l${this:+/}$this"
            eval "${out##-}=\"$s\""
            s="${out##-}"
            [ "$s" == "$out" ] && echo "${!s}"
        else canonical "$1/$this" "$next" $out
        fi
    else
        unset "${out##-}"
    fi
}

function cleanpath {
    local path="/$1/" npath tmp out="$2" oldglob
    if [ $# -eq 1 ]; then cleanpath "$1" CLEAN_PATHNAME
    elif [ $# -eq 2 ]; then
        oldglob=`shopt -p extglob`
        shopt -s extglob
        path="${path//+(\/)//}"
        path="${path//\/.\///}"
        while [ "$path" != "$npath" ]; do
            npath="${path/\/+([^\/])\/..\///}"
            tmp="$path" ; path="$npath" ; npath="$tmp"
        done
        [ -n "${1##/*}" ] && path="${path##/}"
        [ -n "${out##-*}" ] && echo "${path%%/}"
        eval "${out##-}=\"${path%%/}\""
        $oldglob
    fi
}

function relativeto {
    local from="$1" to="$2" out="${3:-REL_PATH}" path=""
    while [ ! -d "$from" ]; do from="${from%/*}" ; done
    [ -n "${from%%/*}" ] && from="$PWD/$from"
    [ -n "${to%%/*}" ] && to="$PWD/$to"
    cleanpath "$from" -from
    cleanpath "$to" -to
    local f=/ t=/
    while [ "$f" == "$t" ]; do
        from="${from#$f}" ; to="${to#$t}"
        from="${from#/}" ; to="${to#/}"
        [ -z "$from" -o -z "$to" ] && break
        f="${from%%/*}" ; t="${to%%/*}"
    done
    path="$to"
    while [ -n "$from" ]; do # common head is above $from
        from="${from%${from##*/}}" ; from="${from%%/}"
        path="../$path"
    done
    [ -n "${out##-*}" ] && echo "$path"
    eval "${out##-}=\"$path\""
}

