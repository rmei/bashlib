# banner saved on Wed Feb 26 14:26:52 PST 2020 to ~/usr/share/shlib/shlib-basic-cli.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 4.4.19(1)-release
function banner () 
{
    : " saved on Wed Feb 26 14:03:02 PST 2020                  ";
    : " to ~/usr/share/shlib/shlib-basic-cli.bash:5-24         ";
    : " from rachels-mac.mei                                   ";
    : "   Darwin, /usr/local/bin/bash, 4.4.19(1)-release       ";
    : ________END_OF_PROVENANCE________;
    local -r fill='################################';
    local text="$2" bar="";
    local -i requested_width="$1" length=${#text};
    local -i width_outer=$(( requested_width - 8 >= length ? requested_width : length + 8 ));
    local -i width_inner=$((width_outer - 8)) i=$width_outer i0;
    while [[ $i -gt 0 ]]; do
        i0=$((i-=${#fill}, ${#fill} + ( i >= 0 ? 0 : i ) ));
        printf -v bar "$bar%${i0}.${i0}s" "$fill";
    done;
    echo "'$bar'";
    printf "'##  %-${width_inner}.${width_inner}s  ##'\n" "$text";
    echo "'$bar'"
} ; 

function join ()
{
    declare sep="$1"; shift
    ( IFS="$sep"; echo "$*"; )
}

realhostname () 
{
    while read L; do
        if [[ "$L" =~ [:\ ]([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
            local ip="${BASH_REMATCH[1]}";
            if host "$ip" > /dev/null; then
                local dns="$(host "$ip")";
                if [[ "$dns" =~ \ ([-.[:alnum:]]+[^.])\.?$ ]]; then
                    local myhost="${BASH_REMATCH[1]}";
                    if [[ ! "$dns" =~ localhost ]]; then
                        echo "$myhost";
                        return 0;
                    fi;
                fi;
            fi;
        fi;
    done <<<"$(ifconfig | grep '\binet\b')"
    hostname;
}

run_if_present() {
    local cmd="$1"; shift
    D "cmd=$cmd $(declare -p ARGS)"
    if [[ -e "$cmd" ]]; then
        bash "$cmd" "$@" "${ARGS[@]}"
    fi
}

report() { reportd 1 "$@" ; }
reportd() {
    local -a args=("$@")
    local -i depth="$1" ; shift
    local status="$1" ; shift
    local msg="$*"
    #local -Ax EMOJI=([ok]='✔' [warn]='⚠️ ' [error]='✘' [noop]='🔸' [info]='ℹ️ ' [check]='✅' [debug]='🔹')
    local -a -x EMOJI=('✔' '⚠️ ' '🛑' '🔸' 'ℹ️ ' '✅' '🔹')
#    local -a -x EMOJI=('✔' '⛔️' '🛑' '🔸' '❗️' '✅' '🔹')
    case "$status" in
        ( ok )      status=0 ;;
        ( warn )    status=1 ;;
        ( error )   status=2 ;;
        ( noop )    status=3 ;;
        ( info )    status=4 ;;
        ( check )   status=5 ;;
        ( debug )   status=6 ;;
    esac
    local indent="" indentstep=" "
    local -i i=0
    while [[ i -lt $depth ]]; do
        indent+="$indentstep"
        i+=1
    done
    local TILDE='~'
    msg="${msg//$HOME/$TILDE}"
    echo "${indent}${EMOJI[status]} $msg"
}

export _SHLIB_BASIC_DEBUG=
function D() {
    [ $_SHLIB_BASIC_DEBUG ] && echo "$@">&2;
}

function DEBUG() {
    local -i offset=0 retval=0
    [ -n "$_DEBUG_STACK_OFFSET_" ] && ((offset+=_DEBUG_STACK_OFFSET_))
    local msg
    msg="$(D "$@" 2>&1)"; retval=$?
    if [ $retval -eq 0 ]; then
        local prefix="${FUNCNAME[offset+1]} (${BASH_SOURCE[offset+1]}:${BASH_LINENO[offset]})";
        report debug "$prefix $msg"
    fi
} ; export -f DEBUG


function get_display_path () {
    local orig="$1" abs="$2"
    if [[ -n "$_VERBOSE" && "$orig" != "$abs" || "$orig" =~ (^|/)".."(/|$) ]]; then
        echo "$abs (as $orig)"
    else
        echo "$abs"
    fi
}

desym() {
    if [[ $# == 1 ]]; then
        local IFS_OLD="$IFS"
        local IFS="/"
        local -a tokens=($1)
        if [[ "$1" =~ ^[^/] ]]; then
            return $LINENO
        fi
        IFS="$IFS_OLD"
        desym . "${tokens[@]}"
    else shift # consume "." marker
        local path="$1" ; shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                ( "." ) ;;
                ( ".." )
                    [[ "${path%/*}" == "$path" ]] && return $LINENO
                    path="${path%/*}"
                ;;
                ( * )
                    local tmp="$path/$1"
                    if [[ -h "$tmp" ]]; then
                        local ref="$(readlink "$tmp")"
                        [[ "$ref" =~ ^[^/] ]] && ref="$path/$ref"
                        path="$(desym "$ref")"
                    else
                        path="$tmp"
                    fi
                ;;
            esac
            shift
        done
        echo "$path"
    fi
}

# normalize <path> <base>
# 
# resolves symlinks, elides /. components, and attempts to cancel /.. components in <path>
# <path> will first be appended to <base> iff <path> is not absolute
# 
normalize() {
    local rel="$1" base="$2"
    [[ "$rel" =~ ^[^/] ]] && rel="$base/$rel"
    # if false; then
    #     while [[ "$rel" =~ ^(.*)(/|^)([^/]*[^/.]\.?|[^/]+\.\.|\.)/\.\./(.*)$ ]]; do
    #         rel="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[4]}"
    #     done
    #     echo "$rel"
    # fi
    desym "$rel"
}

_count_char() {
    local char="$1" text="$2"
    local -i count=0
    while [[ $text ]]; do
        local t="${text%$char*}"
        [[ "$t" = "$text" ]] && break
        ((++count))
        text="$t"
    done
    return $count
}

# relativize A B prints the relative path from directory A to directory B
# 
relativize() {
    : "# relativize /User/rachel/usr/var /User/rachel/Dropbox -> '../../Dropbox' "
    : "# relativize from to"
    local base="$1" target="$2"
    [[ "$base" =~ ^/ ]] || report error "base path ($base) must be absolute"
    [[ "$target" =~ ^/ ]] || report error "target path ($target) must be absolute"
    : TODO: DO THIS CORRECTLY
    : "just strip $HOME for now"
    local b="${base##$HOME}"
    local t="${target##$HOME}"
    if [[ "$b" = "$base" || "$t" = "$target" ]]; then
        : "# they're not both under $HOME; reset them"
        b="$base"; t="$target"
    fi
    t="${t#/}";: "strip leading /"
    _count_char / "$b";
    local -i nesting=$?
    while [[ $((nesting--)) -gt 0 ]]; do
        t="../$t"
    done
    echo "${t%/}" # strip trailing / in case t was null (when $target == $HOME)
}

#
# makes the directory, "$1", with `mkdir -p "$1"`.
# succeeds silently if the creation was successful, or if a directory with that path already exists
# fails if the creation fails, or if that path already exists but is not a directory
#
makedir() {
    declare d="$1"
    if [ -f "$d" ]; then
        report warn "'$d' already exists and is not a directory"
        return $BASH_LINENO
    fi
    if [ -d "$d" ]; then
        return 0
    fi
    if [ -h "$d" ]; then
        declare tmp="$(readlink "$d")"
        pushd "$(dirname "$d")" >/dev/null
        declare type='a nonexistent file'
        [ -d "$tmp" ] && type='a directory'
        [ -f "$tmp" ] && type='a regular file'
        [ -h "$tmp" ] && type='another symlink'
        [ -e "$tmo" ] && type='an unrecognized type of file'
        report warn "'$d' already exists and is a symlink to $type"
        popd >/dev/null
        return $BASH_LINENO
    fi
    if [ -e "$d" ]; then
        report warn "'$d' already exists (and is a nonstandard file type)"
        return $BASH_LINENO
    fi
    mkdir -p "$d"
}

link_to() {
    local src="$1" dst="$2" BACKUP="$3"
    local f #="${src##*/}"
    # preprocess args
    local dst_dir="" f=""
    # f = the basename of $dst
    # dst_dir = the absolutified dirname of $dst
    if [[ "$dst" =~ ^(/)?([^/].*/)?([^/]+)$ ]]; then
        [ -z "${BASH_REMATCH[1]}" ] && dst_dir="$PWD"
        dst_dir+="${BASH_REMATCH[2]:+/}${BASH_REMATCH[2]%/}"
        f="${BASH_REMATCH[3]}"
    else
        report error "couldn't parse source argument \"$dst\""
        return 1
    fi

    local abs_src="$(normalize "$src" "$dst_dir")"
    local display_src="$(get_display_path "$src" "$abs_src")"
    # DEBUG "display_src=$display_src abs_src=$abs_src src=$src dst=$dst BACKUP=$BACKUP f=$f dst_dir=$dst_dir"
    if [[ ! -e "$abs_src" ]]; then
        report warn "requested link target '$abs_src' does not exist"
        return 1 # no source file present; skip silently
    fi

    if [[ -h "$dst" ]]; then # already linked to something. Don’t mess with it.
        local tmp="$(readlink "$dst")"
        local abs_tmp="$(normalize "$tmp" "$dst_dir")"
        if [[ "$tmp" == "$src" ]]; then
            report noop "$dst_dir/$f is already linked to $display_src"
        else
            local display_tmp="$(get_display_path "$tmp" "$abs_tmp")"
            if [[ "$abs_tmp" == "$abs_src" ]]; then
                report warn "$dst is already linked to $abs_src, but as $tmp, not $src"
            else
                report warn "$dst is already linked to $display_tmp, not to $display_src"
            fi
        fi
        return 1
    fi

    if [[ -f "$dst" || -d "$dst" || ! -e "$dst" ]]; then # it's a normal file or directory or hasn't been linked yet.
        if [[ -e "$dst" ]]; then
            if [[ $BACKUP ]]; then
                mkdir -p "$BACKUP" >/dev/null
                if [[ -e "$BACKUP"/"$f" ]]; then
                    if diff "$dst" "$BACKUP/$f" >/dev/null; then
                        #it's already backed-up
                        report noop "\"$dst\" is already backed-up to $BACKUP"
                    else # complain
                        report error "a local backup of \"$dst\" exists, but \"$dst\" is not a symlink!"
                        return $LINENO
                    fi
                fi
                # otherwise, back it up.
                if [[ -f "$dst" ]]; then
                    cp -R "$dst" "$BACKUP"/"$f" && rm "$dst"
                elif [[ -d "$dst" ]]; then
                    mv "$dst" "$BACKUP"/"$f"
                fi
            else
                # else we didn't specify BACKUP and something's still there (in the way). Silently skip.
                DEBUG "didn't specify BACKUP, and \"$dst\" is already present"
            fi
        fi
        if [[ -e "$dst" ]]; then
            DEBUG "hm. document this ..."
        else  # we've successfully backed it up and cleared it out
            report ok "linking $dst_dir/$f to $display_src"
            ln -s "$src" "$dst"
        fi
    else
        report warn "$dst already exists yet is neither a file, nor a symlink, nor a directory; cowardly refusing to process it."
    fi
}

function isset() { declare -p "$1" &>/dev/null; }

function pushshopt () {
    local flag="$1"; shift
    local frame="$(shopt -p "$@" 2>/dev/null)"
    shopt $flag $* || eval "$frame" && return $LINENO
    SHOPT_STACK+=("$frame")
}

function popshopt () {
    local -i i=${1:-1}
    if [ $i -gt ${#SHOPT_STACK[*]} ]; then
        echo "$FUNCNAME: not enough frames (${#SHOPT_STACK[*]}); cannot pop $i" >&2
        return $LINENO
    fi
    for((i=${1:-1};i>0;i--)); do
        eval "${SHOPT_STACK[-1]}" &>/dev/null
        unset SHOPT_STACK[-1]
    done
}

uc () {
    local lcalpha=abcdefghijklmnopqrstuvwxyz ucalpha=ABCDEFGHIJKLMNOPQRSTUVWXYZ
    local sed_trim='s/^[^_[:alnum:]]+|[^_[:alnum:]]+$//g' sed_flatten='s/[^_[:alnum:]]+/_/g'
    echo "$*"|sed -E -e"$sed_trim" -e"$sed_flatten" -ey/$lcalpha/$ucalpha/
}

to_id () {
    pushshopt -s extglob
    local id="${1/#+([^_[:alnum:]])}"
    id="${id/%+([^_[:alnum:]])}"
    echo "${id//+([^_[:alnum:]])/_}"
    popshopt
}

function quoted_val() { local v="$1";[[ "$v" =~ ^[[:alpha:]_][[:alnum:]_]*$ ]]||return $LINENO;v="$(declare -p $v)";echo "${v#*=}"; }
function copy_var() {
    local s="$1" t="$2" tmp
    { [[ "$s" =~ ^[[:alpha:]_][[:alnum:]_]*$ ]] && [[ "$t" =~ ^[[:alpha:]_][[:alnum:]_]*$ ]]; } || return $LINENO
    if tmp="$(declare -p $s 2>/dev/null)"; then
        local val="${tmp#*$s=}"
        local declare_stmt="${tmp%% $s=*}"
        if [[ "${declare_stmt#declare }" =~ a ]]; then
            val="${val#\'}"
            val="${val%\'}"
        fi
        local cmd="$t=$val";
        eval "$cmd"
    else return $LINENO
    fi
}
