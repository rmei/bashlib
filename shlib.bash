#!/bin/bash

#set -vx

declare -x SHLIB_INCLUDE_PATH=( \
    ~/usr/local/share/shlib \
    ~/usr/share/shlib \
    /usr/local/share/shlib \
    /usr/share/shlib \
)

function __join { local IFS="$1" tmp; eval "tmp=(\"\${$2[@]}\"); unset $2; $2=\"\${tmp[*]}\""; }
function __split { local IFS="$1"; eval "${2}_split=(\${$2[*]})"; }
__join ":" SHLIB_INCLUDE_PATH

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

function __include_check3 { for i in "${SHLIB_INCLUSIONS[@]}"; do [ "$1" == "$i" ] && return 42; done; return 0; }
function __include_check4 { [ -n "${SHLIB_INCLUSIONS[$1]}" ] && return 42; return 0; }
function __include_bind3 { SHLIB_INCLUSIONS+=("$1"); }
function __include_bind4 { SHLIB_INCLUSIONS["$1"]=1; }

function __init_bash_ver {
    local ver="$1" pfx="$2" name ; shift 2
    for name in "$@"; do
        eval "function __${pfx}_$name { __${pfx}_$name$ver "'"$@" ; }'
    done
}
if [ $BASH_VERSINFO -ge 4 ]; then
    declare -Ax SHLIB_INCLUSIONS=()
    __init_bash_ver 4 include "check" "bind"
elif [ $BASH_VERSINFO -ge 3 ]; then
    declare -ax SHLIB_INCLUSIONS=()
    __init_bash_ver 3 include "check" "bind"
fi
unset __init_bash_ver

function __include_init {
    local here
    canonical "$BASH_SOURCE" -here
    __include_bind "$here"
}
__include_init
unset __include_init

function include {
    local p="$1" tag="${SHELL##*/}" f i SHLIB_INCLUDE_PATH_split
    __split ":" SHLIB_INCLUDE_PATH
    for f in "$p" "$p.$tag"; do
        for i in . "${SHLIB_INCLUDE_PATH_split[@]}"; do
            [ -r "$i/$f" ] && p="$i/$f" && break 2
        done
    done
    canonical "$p" -p
    __include_check "$p" || return
    source "$p" && {
        __include_bind "$p" && echo " [included '$p']" >&2 || echo \
        " [ERROR in shlib; sourced '$p' but could not bind to SHLIB_INCLUSIONS]" >&2
    }
}

function __arraycopy() {
    local src="$1" dst="$2" k
    eval "for k in \"\${!$src[@]}\"; do $dst[\$k]=\"\${$src[\$k]}\"; done"
}

function __dump() {
    __debug && for name in $@; do
        local k a="${name%\[[*@]\]}"
        if [ "$name" != "$a" ]; then
            local -a keys
            eval 'keys=("${!'"$a"'[@]}")'
            local m
            if [ ${#keys[@]} -gt 0 ]; then m=""; else m=" EMPTY"; fi
            echo "$name:$m"
            for k in "${keys[@]}"; do eval 'echo "  [$k]=${'"$a"'['"$k"']}"'; done
        else
            local b="${name//[^\[]}"
            eval 'echo "$name=$'${b:+\{}"$name"${b:+\}}'"'
        fi
    done
}

function __debug() { true; }
