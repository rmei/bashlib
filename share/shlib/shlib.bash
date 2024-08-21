
function _cleanup ()
{
    local rc=$?
    : @file 2 11 ~/usr/share/shlib/shlib.bash
    while [[ $# -gt 0 ]]; do
        [[ "$1" && -e "$1" ]] && rm "$1"
        shift
    done
    return $rc
}

function update_line_numbers () 
{
    : @file 13 20 ~/usr/share/shlib/shlib.bash
    local file="$1"
    function _mod () { perl ~/usr/bin/update_line_numbers.pl "$1" "$2" > "$3"; }
    _modify_with_backup "$file" 3 _mod {IN} "$file" {OUT}
    unset _mod
}

hrstars='　　　⟢　⟡　⟣'
dirlist() { find "$1" -type f; ll -R "$1"; }
experiment() { rm -fr usr/share/shlib/.shlib-backup/; echo $hrstars; dirlist usr/share/shlib/.shlib-backup; echo $hrstars; source usr/share/shlib/shlib.bash; dirlist usr/share/shlib/.shlib-backup; }


invocation_id() {
    local -a _lineno
    _() { _lineno=("$@");}; _ "${BASH_LINENO[@]}"; unset _
    local LINENODOTS="$(IFS=.;echo "${_lineno[*]}")" # /${BASH_SOURCE[*]}
:<<-"END"
    1. LINENODOTS: dotted-sequence of line numbers of shell function stack frames (this process only)
    2. BASH_SUBSHELL: nested subshell depth (can distinguish corner cases)
    3. SHLVL: # of nested bash process invocations (can distinguish across calls ... PPID-traversal stack trace would be better)
    4. BASHPID: subshell-unique PID (unique-ish ID, varies arbitrarily)
END
    echo "$linenodots,$BASH_SUBSHELL,$SHLVL,$BASHPID"
}

function gnu () {
    local CMD="$1"; shift
    if which g"$CMD" &>/dev/null; then g"$CMD" "$@"; else "$CMD" "$@"; fi
}

function date_ () {
    : @file 45 48 ~/usr/share/shlib/shlib.bash
    date "$@" +%Y%m%dT%H%M%SZ
}

function gdate_ () { gnu date "$@" +%Y%m%dT%H%M%S,%03NZ; }

function _modify_with_backup ()
(
    local -r timestamp="$(date_)"
    local -r thread="$(invocation_id)"
    local -r host_label="$HOSTNAME"
    local -r -i MAX_TRIES=3
    local -r BACKUPDIRNAME=.shlib-backup
    local -r target_file="$1" ; shift;
    local -r -i retry=$(( $1 > MAX_TRIES ? MAX_TRIES : $1 )) ; shift;
    local -r -a command_template=("$@")
    # # need to substitute {} with $1 in values of command[*]
    # local -i i
    # for (( i=0; i<${#command[*]}; i++ )); do
    #     [[ "${command[$i]}" == '{IN}' ]] && placeholders_in+=($i)
    #     [[ "${command[$i]}" == '{OUT}' ]] && placeholders_out+=($i)
    # done

    # echo "${command[*]}" >&2
    # echo "${placeholders_in[*]}" >&2
    # echo "${placeholders_out[*]}" >&2

    local target_dir="$(dirname "$target_file")"
    if [[ -w "$target_file" && -d "$target_dir" && -w "$target_dir" ]]; then
        : "we can modify the file and its surrounds; proceed"
        local base="$target_dir/$BACKUPDIRNAME"
        local context="$base/$(basename "$target_file")"
        local backup_file="$context,$timestamp,$thread"
        local tmp="$backup_file.tmp"
        local wk="$base/$thread"
        if [[ -e "$wk" ]]; then
            echo "Warning: '$wk' already exists! Probably trampling on someone else's execution ..." >&2
        else
            mkdir -p "$wk" &>/dev/null
        fi

        # take the snapshot we'll preserve if we commit
        ln "$target_file" "$wk"/tmp
        cp "$wk"/tmp "$wk"/snapshot
        rm "$wk"/tmp
        chmod a-w "$wk"/snapshot # nobody should be writing to this anymore

        # we probably can toss this part
        : 'some bookkeeping around the most recent pre-existing snapshot ...'
        local latest="$(ls -r "$context"* 2>/dev/null | head -1)"
        if [[ $latest ]]; then
            ln "$latest" "$wk"/latest
            if diff "$wk/snapshot" "$wk/latest" &>/dev/null; then
                : "they're the same. wut? oh well."
            else
                : "source has changed since the last snapshot"
            fi
        fi

        _subst() {
            : 'substitute "$wk"/... for "{*}" markers in command_tmp'
            local -i i
            for (( i=0; i<${#command_template[*]}; i++ )); do
                case "${command_template[$i]}" in
                    ('{IN}')  command_tmp[$i]="$wk"/snapshot ;;
                    ('{OUT}') command_tmp[$i]="$wk"/out ;;
                    (*) command_tmp[$i]="${command_template[$i]}" ;;
                esac
            done
        }; local -a command_tmp=(); _subst; unset _subst
        local -r -a command=("${command_tmp[@]}")
        unset command_tmp


        trap "_cleanup '$tmp'" INT TERM EXIT
        local -i result=12345
        # do the actual processing
        : 'perl ~/usr/bin/update_line_numbers.pl "$wk"/snapshot "$target_file" > "$tmp"'
        ( "${command[@]}" ) ; result=$?
        local -i tries=1
        # potentially handle errors
        until [[ $result -eq 0 || $tries -ge $retry ]]; do
            echo "problem processing '$target_file' with '$command[0]'; retrying ..." >&2
            sleep 1
            : 'perl ~/usr/bin/update_line_numbers.pl "$wk"/snapshot "$target_file" > "$tmp"'
            ( "${command[@]}" ) ; result=$?
            if [[ $result -eq 0 ]]; then
                echo "success!" >&2
            else
                tries+=1
            fi
        done

        # handle error cases, or commit if there are none
        if [[ $result -ne 0 && $tries -ge $retry ]]; then
            echo "Too many failed attempts: $tries. Not updating '$target_file'" >&2
        elif [[ ! -e "$wk"/out ]]; then
            echo "Error: command did not produce the expected output file ($wk/out). Not updating '$target_file'" >&2
        elif diff "$wk"/snapshot "$wk"/out &>/dev/null ; then
            : "command did not modify the content; we're done here."
            rm -fr "$wk"
        elif false ; then : 'should test for concurrent update, here'
        else : 'nothing seems to have gone wrong; update $target_file'
            mv "$wk"/snapshot "$backup_file"
            mv "$wk"/out "$target_file" # atomic update
            rm -fr "$wk"
        fi

        trap - INT TERM EXIT
    else
        : "cannot modify '$target_file' or '$target_dir'"
    fi
)

# source saved on Thu Nov  7 16:04:16 PST 2019 to ~/usr/share/shlib/shlib.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.11(1)-release
function source () 
{
    : " saved on Thu Nov  7 16:04:16 PST 2019                 "
    : " to ~/usr/share/shlib/shlib.bash:161-171               "
    : " from rachels-mac.mei                                  "
    : "   Darwin, /usr/local/bin/bash, 5.0.11(1)-release      "
     : ________END_OF_PROVENANCE________
 
    local f="$1";
    [[ -e "$f" ]] && update_line_numbers "$f" && builtin source "$f"
}

source "$(dirname "$BASH_SOURCE")"/shlib-tools.bash

if [[ -z "$1" ]]; then
    # re-load this file, updating line numbers
    source "$BASH_SOURCE" 1
fi
