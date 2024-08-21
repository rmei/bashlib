#!/bin/bash

function _hashcopy() {
    local _hashcopy_src="$1" _hashcopy_dst="$2" k
    eval "for k in \"\${!$_hashcopy_src[@]}\"; do $_hashcopy_dst[\$k]=\"\${$_hashcopy_src[\$k]}\"; done"
}

function _arraycopy() {
    local _arraycopy_src="$1" _arraycopy_dst="$2"
    eval "$_arraycopy_dst=(\"\${$_arraycopy_src[@]}\")"
}

function _reverse_array() {
    local name="$1"
    local step="$2"
    [[ -n "$step" ]] || step=1
    local -ax src dst
    _arraycopy $name src
    #declare -p src
    [[ $(( ${#src[*]} % step )) -gt 0 ]] && exit 1;
    local i=0 j tmp offset
    while [[ "$i" -lt "${#src[*]}" ]]; do
        offset=$(( ${#src[*]} - step - i ))
        j=0
        while [[ $j -lt $step ]]; do
            dst[offset + j]="${src[i + j]}"
            j=$(( j + 1 ))
        done
        i=$(( i + step ))
    done
    _arraycopy dst $name
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

function list { local _list="$2" IFS=$'\n'; eval "$1=(\$_list)"; }

function list_to_path { local IFS=":"; echo "$*"; }

function Join() { local IFS="$1"; shift; echo "$*"; }

function Join_by_name() { local IFS="$1"; eval 'echo "${'"$2"'[*]}"'; }

function __debug() { true; }
