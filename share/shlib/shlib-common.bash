##
## TODO:
##
:<<'END_TODO'
 
END_TODO
 
function ~dbg {
    : @file 8 13 ~/usr/share/shlib/shlib-common.bash
    if [ "$dbg" ] || declare -p dbg_${FUNCNAME[1]}&>/dev/null; then
        echo "${FUNCNAME[1]}: $*">>~/Debug
    fi
}

function Debug ()
{
    : @file 15 27 ~/usr/share/shlib/shlib-common.bash
    if [ "$DEBUG" ]; then
        local func="${FUNCNAME[1]}"
        if [[ "$func" == $DEBUG ]]; then
            local file="${BASH_SOURCE[1]##*/}"
            local line="${BASH_LINENO[2]}"
            local prefix="$file${line:+($line)}${file:+${line:+:}}$func"
            echo "${prefix:+$'\e[1;36m'<$prefix>$'\e[0m'} $@" >&2
        fi
    fi
}
 
function graberr { local -i r=$?; eval "$1=$r"; return $r; }
 
function _is_declared () {
    : @file 31 34 ~/usr/share/shlib/shlib-common.bash
    declare -p "$@" >/dev/null 2>&1
}
 
# _is_array saved on Wed Mar 10 11:19:37 PST 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function _is_array () 
{
    : @file 37 46 ~/usr/share/shlib/shlib-common.bash
    local decl name="$1";
    if decl=( $(declare -p "$name" 2>/dev/null) ) && [[ "${decl[1]}" =~ ^-.*a.* ]]; then
        return 0;
    else
        return 1;
    fi
} ; 
 
function xmul ()
{
    : @file 48 56 ~/usr/share/shlib/shlib-common.bash
    local str="$1"
    local -i x=$2
    for (( ; x > 0; x-- )); do
        echo -n "$str"
    done
}
 
function _find_index () {
    local s query="$1" ; shift
    local -a list=("$@")
    local -i i
    for (( i=0; i < $#; i++ )); do
        if [[ "${list[$i]}" =~ $query ]]; then
            echo $i
            return 0
        fi
    done
    echo -1
    return 1
}
 
#
# canonical [opts] path
#
#  Calculates the canonical path for the file/dir referenced by path,
# assigns this value to "canonical", and prints it to stdout.
# The canonical path is an absolute path containing no symbolic links.
#
# options:
#   -q              do not print to stdout
#   -v varname      assign to "varname" instead of "canonical"
#
function canonical
{
    : @file 83 114 ~/usr/share/shlib/shlib-common.bash
    local quiet varname opt OPTARG OPTIND=1
    while getopts "qv:" opt; do
        case "$opt" in
        q) quiet=1 ;;
        v) varname="$OPTARG" ;;
        esac
    done ; shift $((OPTIND-1))
    local l temp this next r="$1"
    [ $# -ne 1 ] && { unset ${varname:+canonical} ; return 42 ; }
    [ -n "${r%%/*}" ] && r="$PWD/$r"
    while [[ 1 ]]; do
        r="$r/" ; r="${r//\/.\///}" ; r="${r%%/}" ; r="${r##/}"
        this="${r%%/*}" ; next="${r#$this}" ; next="${next##/}"
        if [ -L "$l/$this" ]; then # dereference symlinks
            temp=`readlink "$l/$this"`
            r="${temp%%/}/$next"
            [ -z "${temp%%/*}" ] && l="" # it's absolute; reset
        elif [ "$this" == "." ]; then r="$next"
        elif [ "$this" == ".." ]; then r="$next" ; l="${l%/*}"
        elif [ -n "$r" ]; then l="$l/$this" ; r="$next"
        else # Done!
            temp="$l${this:+/}$this"
            [ -z "$quiet" ] && echo "$temp"
            if [ -z "$varname" ]; then canonical="$temp"
            else eval "$varname=\"$temp\"" ; fi
            return 0
        fi
    done
}
 
##########
#  I/O  ##
##########
 
function listarray() {
    local IFS=$'\n'
    echo "$*"
}
 
function error_message {
    : @file 125 130 ~/usr/share/shlib/shlib-common.bash
    : @uses ~log_message
    ~log_message 1 "\e[31mERROR\e[m" "$@"
    return 1
}
 
 
function warning_message {
    : @file 133 137 ~/usr/share/shlib/shlib-common.bash
    : @uses ~log_message
    ~log_message 1 WARNING "$@"
}
 
function ~log_message {
    : @file 139 162 ~/usr/share/shlib/shlib-common.bash
    local nested="$1" category="$2" context="" message
    shift 2;
    if [[ $# -gt 1 ]]; then
        context="$1";
        shift;
        message="$*";
    else
        message="$1";
        context=0
    fi;
    if [ $context ] && [[ "$context" =~ ^[[:digit:]]+$ ]]; then
        context="${FUNCNAME[context + nested + 1]}"
    fi
    # perform ANSI-SGR markup, here
    message="${category:+$category: }${context:+$context: }$message"
    message="${message//\\e/$'\e'}"
    if [[ -t 2 ]]; then
        echo "${message//$HOME/$TILDE}" >&2
    else
        perl -npe's%\x1b\[[\d;]*m%%g'<<<${message//$HOME/$TILDE} >&2
    fi
}
 
function fecho() {
    : @file 164 168 ~/usr/share/shlib/shlib-common.bash
    local f="$1"; shift
    echo "$@" >> "$f"
}
 
function _warn ()
{
    : @file 170 179 ~/usr/share/shlib/shlib-common.bash
    local TILDE='~'
    if [[ -t 1 ]]; then
        echo "${*//$HOME/$TILDE}"
    else
        perl -npe's%\x1b\[[\d;]+m%%g'<<<${*//$HOME/$TILDE}
    fi
}
 
function _log ()
{
    : @file 181 190 ~/usr/share/shlib/shlib-common.bash
    local TILDE='~'
    if [[ -t 1 ]]; then
        echo "${*//$HOME/$TILDE}"
    else
        perl -npe's%\x1b\[[\d;]+m%%g'<<<${*//$HOME/$TILDE}
    fi
}
 
function _style_file ()
{
    : @file 192 196 ~/usr/share/shlib/shlib-common.bash
    echo -e "\\e[1;4m$*\\e[0m"
}
 
function _style_lineno ()
{
    : @file 198 202 ~/usr/share/shlib/shlib-common.bash
    echo -e "\\e[1;4m$*\\e[0m"
}
 
function _bold_list ()
{
    : @file 204 212 ~/usr/share/shlib/shlib-common.bash
    local s=$1; shift
    echo -ne "\\e[1m$s\\e[0m"
    for s in "$@"; do
        echo -ne ", \\e[1m$s\\e[0m"
    done
}
 
# in_red saved on Mon Jan 25 14:11:41 PST 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function in_red () 
{
    : @file 215 219 ~/usr/share/shlib/shlib-common.bash
    perl -ne 'print "\e[31;1m$_\e[0m"'
} ; 
 
# plural saved on Wed May 26 13:19:30 PDT 2021 to ~/usr/share/shlib/shlib-common.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function plural () 
{
    : @file 222 232 ~/usr/share/shlib/shlib-common.bash
    local -i n=$1;
    local plural="${2-s}" singular="$3";
    if [ "$n" -eq 1 ]; then
        echo "$singular";
    else
        echo "$plural";
    fi
} ; 
 
# banner saved on Wed Feb 26 14:04:46 PST 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 4.4.19(1)-release
function banner () 
{
    : @file 235 250 ~/usr/share/shlib/shlib-common.bash
    local -r fill='################################';
    local text="$2" bar="";
    local -i requested_width="$1" length=${#text};
    local -i width_outer=$(( requested_width - 8 >= length ? requested_width : length + 8 ));
    local -i width_inner=$((width_outer - 8)) i=$width_outer i0;
    while [[ $i -gt 0 ]]; do
        i0=$((i-=${#fill}, ${#fill} + ( i >= 0 ? 0 : i ) ));
        printf -v bar "$bar%${i0}.${i0}s" "$fill";
    done;
    echo "$bar";
    printf "##  %-${width_inner}.${width_inner}s  ##\n" "$text";
    echo "$bar"
} ; 
 
# stringfill saved on Wed Feb 26 14:04:47 PST 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 4.4.19(1)-release
function stringfill () 
{
    : @file 253 262 ~/usr/share/shlib/shlib-common.bash
    local -i i length="$1";
    local string="$2";
    while [[ $length -gt 0 ]]; do
        i=$((length-=${#string}, ${#string} + ( length >= 0 ? 0 : length ) ));
        printf "%${i}.${i}s" "$string";
    done
} ; 
 
function join {
    : @file 264 277 ~/usr/share/shlib/shlib-common.bash
    local delimiter="$1"; shift
    if [ ${#delimiter} -eq 1 ]; then
        local IFS="$delimiter"
        echo "$*"
    else
        echo -n "$1"; shift
        while [ $# -gt 0 ]; do
            echo -n "$delimiter$1"
            shift
        done
    fi
}
 
function compare_lists() {
    : @file 279 286 ~/usr/share/shlib/shlib-common.bash
    local left="$1" right="$2" op="$3" result="$4"
    diff "$left" "$right" | grep "^$op " | cut -c3- > "$result"
    if [ "$result" = "/dev/stdout" ]; then true
    else [ $(wc -l < "$result") -gt 0 ]
    fi
}
 
function successor() {
    : @file 288 313 ~/usr/share/shlib/shlib-common.bash
    local sentinel="" found="" cursor
    local target="$1"; shift
    if [ "$target" == "-s" ]; then
        sentinel="$1"
        target="$2"
        shift 2
    fi
    local -a list=("$@")
    for cursor in "${list[@]}"; do
        if [ "$found" ]; then
            echo "$cursor"
            return 0
        elif [ "$cursor" == "$target" ]; then
            found=1
        fi
    done
    if [ "$found" ]; then
        echo ""
        return 0
    else
        echo "warning, '$target' not in list: [ ${list[*]} ]" >&2
        return 1
    fi
}
 
function is_in_list() {
    : @file 315 330 ~/usr/share/shlib/shlib-common.bash
    : @uses warning_message
    local val="$1"; shift
    local -i pos=0
    [ $# -eq 0 ] && warning_message "$FUNCNAME called with no arguments ..."
    while [ $# -gt 0 ]; do
        if [ "$val" = "$1" ]; then
            _is_declared _list_pos && _list_pos=$pos
            return 0
        fi
        : $((++pos))
        shift
    done
    return 1
}
 
function sleep_until_keystroke() {
    : @file 332 340 ~/usr/share/shlib/shlib-common.bash
    local line
    if read -r -s -n 1 ${1:+-t $1} line; then
        return 13
    else
        return 0
    fi
}
 
function here() {
    : @file 342 376 ~/usr/share/shlib/shlib-common.bash
    : @uses error_message
    local -i depth="$1"
    local val
    val="$(dirname "${BASH_SOURCE[depth+1]}")"
    if [[ "$val" =~ ^/dev($|/) ]]; then
        local declaring_file="$(declare -f "${FUNCNAME[depth+1]}" | grep '@file ' | head -1)"
        if [[ "$declaring_file" =~ :" "+@file" "+[0-9]+" "+[0-9]+" "+([^ #][^#]*[^ ]) ]]; then
            declaring_file="${BASH_REMATCH[1]}"
        else
            error_message "${FUNCNAME[depth+1]} does not appear to have a properly-formatted ': @file ...' tag; 'here' cannot proceed."
            echo "__ERROR__HERE__${FUNCNAME[depth+1]}_LACKS_WELL_FORMED_FILE_TAG__"
            return 1
        fi
        val="$(dirname "$declaring_file")"
        # local file_here_fn
        # file_here_fn="${declaring_file//[^A-Za-z0-9\-/_}"
        # if declare -f "$file_here_fn" &>/dev/null; then
        #     "$file_here_fn"
        # else
        #     error_message "Cannot locate function '$file_here_fn' used to compensate for loadfn-based selective source streams. Attempting to source '$declaring_file' directly."
        #     if builtin source "$declaring_file"; then
        #     else
        #         return 1
        #     fi
        # fi
    fi
    if [ "$1" == '-a' ]; then # want absolute path, not tilde-prefixed
        val="${val/#~\//$HOME/}"
    elif [ "$1" == '-p' ]; then # want tilde-prefixed path if possible, not absolute
        val="${val/#$HOME\//~/}"
    fi
    echo "$val"
}
