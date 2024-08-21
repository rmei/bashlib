#!/bin/bash

function compgend_local {
    local reply="$1" path="$2" base="$3" p q IFS=$'\n'
    for p in `compgen -d "$path$base"`; do # | (while read ; do x; done)
        q="${p#$path}"
        eval "$reply+=(\"\$q\")"
    done
}
