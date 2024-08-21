##
## TODO:
##
:<<'END_TODO'
fn_location:
    use shopt -s extdebug / declare -F fname if no @file tag found
    use default source locations + grep if no metadata available at all
loadfn:
    read @uses from sourcefile, not declare
    be silent when declare errors-out (allow load of new fns from file)
savefn:
    should detect if any fn args are actually files and error-out, suggesting "did you mean `-f ____` ?"
editfn:

END_TODO



# declare -x SHLIB_INCLUDE_DIRS=(
#     ~/usr/local/share/shlib
#     ~/usr/site/arch/share/shlib
#     ~/usr/site/share/shlib
#     ~/usr/arch/share/shlib
#     ~/usr/share/shlib
#     /usr/local/share/shlib
#     /usr/share/shlib
# )

# function __util_split { local IFS="$1"; __split=(${!2}) ; }
# function __util_join { local IFS="$1"; eval "$3=\"\${$2[*]}\""; }
# __util_join ":" SHLIB_INCLUDE_DIRS SHLIB_INCLUDE_PATH

[[ -n "$FUNCTION_FILE" ]] || \
    export FUNCTION_FILE=~/.bashrc

function init_usage {
    : @file 36 48 ~/usr/share/shlib/shlib-fn.bash
    : @uses error_message
    if declare -p Usage >/dev/null 2>&1; then
        Usage=$(cat)
        local globopts="$(shopt -p extglob)"
        shopt -s extglob;
        Usage="Usage: ${FUNCNAME[1]} ${Usage#+( )}"
        eval "$globopts"
    else
        error_message "init_usage: must predeclare \$Usage"
    fi
}

[[ "$ALIAS_FILE" ]] || \
    export ALIAS_FILE=~/.bash_aliases

function savealias () 
{
    : @file 53 103 ~/usr/share/shlib/shlib-fn.bash
    local tstamp
    local -i result=0
    [[ "$ALIAS_FILE" ]] || ALIAS_FILE=~/usr/etc/bash_aliases
    if [[ "$1" =~ -v ]]; then shift
        local v=true vv=true
    elif [[ "$1" =~ -q ]]; then shift
    else local v=true
    fi
    if [[ $# -eq 0 ]]; then
        [[ $v ]] && echo " Usage:  $FUNCNAME name [name ...]"
    else
        tstamp=$'\t\t'"# saved $(date)"
        for name in "$@"; do
            local def old
            local -i definition_err
            def="$(alias $name 2>&1)"; graberr definition_err
            if [[ $definition_err -gt 0 ]]; then
                result=$definition_err
                echo " problem with '$name': $def" >&2
                continue
            elif old="$(grep -oE '(##\S+\s+)?alias\s+'"$name"$'=[^\t]+' "$ALIAS_FILE")"; then
                if [[ "$old" =~ ^\s*##ignore" " ]]; then
                    [[ $v  ]] && echo " '$name' is flagged to ignore${vv:+ in $ALIAS_FILE}"
                    [[ $vv ]] && echo "    $old"
                    continue
                elif [[ "$old" =~ \$ ]]; then
                    [[ $v  ]] && echo " '$name' is calculated programmatically at init${vv:+ in $ALIAS_FILE}"
                    [[ $vv ]] && echo "    $old"
                    continue
                elif [[ "$def" == "$old" ]]; then
                    [[ $v  ]] && echo " '$name' is unchanged${vv:+ from value in $ALIAS_FILE}"
                    [[ $vv ]] && echo "    existing value: $old"
                    continue
                else
                    [[ $v  ]] && echo " overrode '$name'${vv:+ in $ALIAS_FILE}"
                    [[ $vv ]] && echo "    old_value: $(grep -E '^\s*(##\S+\s+)?alias\s+'"$name=" "$ALIAS_FILE")"
                    grep -vE '^\s*(##\S+\s+)?alias\s+'"$name=" "$ALIAS_FILE" > "$ALIAS_FILE"
                    [[ $vv ]] && echo "    new value: $def$tstamp"
                fi
            else
                [[ -w "$ALIAS_FILE" ]] || touch "$ALIAS_FILE"
                [[ $v  ]] && echo " saved '$name'${vv:+ to $ALIAS_FILE}"
            fi
            echo "$def$tstamp" >> "$ALIAS_FILE"
        done
    fi
    return $result
} ; complete -A alias savealias

# stack_trace saved on Wed Nov  6 13:17:24 PST 2019 to ~/usr/share/shlib/shlib.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.11(1)-release
function stack_trace () 
{
    : " saved on Wed Nov  6 13:17:24 PST 2019                 "
    : " to ~/usr/share/shlib/shlib-fn.bash:106-135            "
    : " from rachels-mac.mei                                  "
    : "   Darwin, /usr/local/bin/bash, 5.0.11(1)-release      "
     : ________END_OF_PROVENANCE________
 
    local msg;
    [[ $# -gt 0 ]] && echo "$*";
    local indent="  ";
    local -a args;
    local -i i frames=$(( ${#BASH_SOURCE[*]} - 1 ));
    for ((i=0; i < frames; i++))
    do
        args=(`caller $i`);
        local line=${args[0]} name=${args[1]};
        local file="${args[*]:2}";
        echo "$indent$file:$line $name" >&2;
    done;
    local pid ppid=$BASHPID;
    while args=(`ps -o pid=,ppid=,command= -p $ppid`); do
        pid=${args[0]};
        [[ "$pid" -ne "$ppid" ]] && echo "$pid != $ppid" 1>&2;
        ppid=${args[1]};
        [[ ${args[2]} =~ ^- ]] && break;
        echo "$indent${args[*]:2}" >&2;
    done
    echo >&2;
} ; # declare -fx stack_trace

function _fn_patterns ()
{
    : @uses _is_declared @file 137 151 ~/usr/share/shlib/shlib-fn.bash
    _is_declared TAB && TAB=$'\t' || local TAB=$'\t'
    _is_declared NL && NL=$'\n' || local NL=$'\n'

    _is_declared tagprefix &&
        tagprefix="[;{$NL][[:space:]]*(true[[:>:]]|:)[^$NL]*[ $TAB]"
    _is_declared filepattern &&
        filepattern=" +([0-9]+|-) +(-|[0-9]+) +([^;@[:space:]]([^;@$NL]*[^;@[:space:]])?)"
    _is_declared topattern &&
        topattern="([^:;@$NL$TAB]+):([[:digit:]]+)-([[:digit:]]+)"
    _is_declared usespattern &&
        usespattern="(([ $TAB]+[-_~[:alnum:]]+)*)"
}

function fn_depends ()
{
    : @file 153 162 ~/usr/share/shlib/shlib-fn.bash
    : @uses fn_depends_tree Debug
    Debug "($*)"
    eval "function _fn_depends_tmp () { true @uses $*; }"
    local -a tmp=( $(perl -e'local $/;$_=<>;s%\s*#.+%%gm;print'<<<$(fn_depends_tree _fn_depends_tmp 0 $@))  )
    unset -f _fn_depends_tmp
    echo "${tmp[*]}"
} ; complete -o default -A function fn_depends

function fn_depends_tree ()
{
    : @file 164 200 ~/usr/share/shlib/shlib-fn.bash
    : @uses fn_uses _is_declared xmul
    local fn="$1"
    local -i depth=${2:-0}
    Debug "entered $*"
    if ! _is_declared roots; then
        shift 2; local -a roots=( $fn "$@" )
    fi
    if ! _is_declared seen; then
        Debug "declaring seen (in $fn)"
        local -a seen=()
    fi
    local dep is_dupe is_root
    for dep in "${seen[@]}"; do
        [[ "$dep" == "$fn" ]] && is_dupe=true && break;
    done
    for dep in "${roots[@]}"; do
        [[ "$dep" == "$fn" ]] && is_root=true && break;
    done
    seen+=($fn)
    echo -n "$(xmul '  ' $depth)"
    if [[ $is_root ]]; then
        echo "#$fn (root)"
    elif [[ $is_dupe ]]; then
        echo "#$fn (duplicate)"
        return
    else
        echo $fn
    fi
    local -a used=();
    fn_uses $fn # sets used=(...)
    for dep in "${used[@]}"; do
        fn_depends_tree $dep $(( depth + 1 ))
    done
} ; complete -o default -A function fn_depends_tree

function fn_uses () {
    : @file 202 233 ~/usr/share/shlib/shlib-fn.bash
    : @uses _fn_patterns _is_declared
    local fn=$1
    local definition="$(declare -f -p $fn)"
    local tagprefix usespattern ; _fn_patterns
    if _is_declared used; then
        used=()
    else
        local -a used
        local do_echo=true
    fi
    #Debug "${BASH_REMATCH[1]} : '$definition'"
    while [[ "$definition" =~ $tagprefix"@uses"$usespattern ]]; do
        definition="${definition//@uses${BASH_REMATCH[2]}}"
        #Debug "${BASH_REMATCH[1]} : '$definition'"
        used+=( ${BASH_REMATCH[2]} )
    done
    definition="$(complete -p $fn 2>/dev/null)"
    if [[ "$definition" =~ " -F "([_~[:alnum:]]+) ]]; then
        Debug "found compspec: $definition (${BASH_REMATCH[1]})"
        used+=( ${BASH_REMATCH[1]} )
    fi
    local subfn
    for subfn in $(declare -F | grep "^declare -f ~${fn}~" | cut -d' ' -f3); do
        used+=("$subfn")
    done
    local tmp
    [ $do_echo ] && for tmp in "${used[@]}"; do
        echo "$tmp"
    done # still need to capture completion dependency
} ; complete -o default -A function fn_uses


function fn_location () {
    : @uses _fn_patterns @file 236 267 ~/usr/share/shlib/shlib-fn.bash
    local fn=$1
    local globopts="$(shopt -p extglob)"
    shopt -s extglob;
    local -i start=0 end=0 length=0
    local file definition="$(declare -f -p $fn 2>/dev/null)"
    local tagprefix filepattern topattern ; _fn_patterns
    Debug "$definition"
    if [[ "$definition" =~ (true|:)" \" to "+$topattern ]]; then
         Debug "${BASH_REMATCH[*]:0:5}"
        file="${BASH_REMATCH[2]}"
        start="${BASH_REMATCH[3]}"
        end="${BASH_REMATCH[4]}"
    elif [[ "$definition" =~ $tagprefix"@file"$filepattern ]]; then
         Debug "${BASH_REMATCH[*]:0:5}"
        if [ "${BASH_REMATCH[2]}" != '-' -a "${BASH_REMATCH[3]}" != '-' ]; then
            start="${BASH_REMATCH[2]}"
            end="${BASH_REMATCH[3]}"
        fi
        file="${BASH_REMATCH[4]}"
    else
        false
    fi
    local retval=$?
    if [ $retval -eq 0 ]; then
        length=$(( 1 + end - start ))
        echo "$start $length $file"
    fi
    eval "$globopts"
    return $retval
} ; complete -o default -A function fn_location

function base_getopts ()
{
    : @file 269 290 ~/usr/share/shlib/shlib-fn.bash
    #true @writes opt_file OPTIND
    local opt OPTARG Usage="$1" ; shift
    OPTIND=1;
    while getopts "hf:" opt; do
        case "$opt" in 
            h)
                echo "$Usage";
                return 1;
            ;;
            f)
                opt_file="$OPTARG";
            ;;
            ?)
                return $?
            ;;
        esac;
    done;
    return 0;
}

function validate_file () 
{
    : @file 292 310 ~/usr/share/shlib/shlib-fn.bash @uses usage_error
    local file="$1" context="$2";
    if [[ -e "$file" ]]; then
        if [[ -d "$file" ]]; then
            usage_error "$context" "can't save to $file, it is a directory. Specify a different file.";
            return 11;
        fi;
        if [[ ! -w "$file" ]]; then
            usage_error "$context" "can't save to $file, it is read-only. Specify a different file.";
            return 12;
        fi;
    else
        usage_error "$context" "$file: file not found";
        return 13;
    fi;
    return 0
};

function usage_error () {
    : @file 312 317 ~/usr/share/shlib/shlib-fn.bash @uses error_message
    error_message "$@"
    [ -n "$Usage" ] && echo "$Usage" | head -1 1>&2
    return 17
}

function fn_find_definition ()
{
    : @file 319 345 ~/usr/share/shlib/shlib-fn.bash
    [ $# -ge 2 ] || error_message "too few parameters" || return 1
    local file="$1" ; shift
    local fn fns=$1 ; shift
    for fn in "$@"; do
        fns+="|$fn"
    done
    Debug "$fns, \"$file\""
    perl - <<-"END_PERL" "$fns" "$file"
        my $fns = shift;
        do {local $/;$_=<>};
        print "\n$1\n" while m{
        ^ [ \t]* (
            (?:
                function \s+ (?: $fns ) (?: \s* \(\) )?
              | (?: $fns ) \s* \(\)
            )
            \s+ \{
            (?: # a one-liner or a multiline block
                [ \t]+[^\n]+ ; \s* \} [ \t]* (?: [ \t] \# [^\n]* )? $
              | \s+ .+? ^\} [^\n]* $
            )
        )}xmsg;
END_PERL
}

function visit_file () 
{
    : @file 347 358 ~/usr/share/shlib/shlib-fn.bash
    local f file="$1";
    require_var visited_files || return;
    require_var i || return;
    for (( i=0; i< "${#visited_files[*]}"; i++)); do
        [[ "${visited_files[$i]}" == "$file" ]] && return;
    done;
    visited_files+=("$file")
    i=$(( ${#visited_files[*]} - 1 ))
};

function _store_for_file () {
    : @uses require_var warning_message _warn Debug visit_file
    : @file 360 375 ~/usr/share/shlib/shlib-fn.bash
    require_var visited_files || return
    require_var vals || return
    local file="$1" value="$2"
    [[ $# -ne 2 ]] && warning_message "wrong number of parameters (expected 2; was $#)" && Debug "$*"
    local -i i
    visit_file "$file"
    if [[ -n "${vals[$i]}" ]]; then
        vals[$i]+=" $value"
    else
        vals[$i]="$value"
    fi
    Debug "$file" "${vals[$i]}"
}

function lines {
    : @file 377 381 ~/usr/share/shlib/shlib-fn.bash
    local args="$*" IFS=$'\n'
    lines=($args)
}

function linenos () {
    : @file 383 402 ~/usr/share/shlib/shlib-fn.bash
    : @uses _style_lineno lines
    declare -i line_number
    declare line
    local content
    if true; then # TODO: only when stdin is not a terminal
        read -t 3 -d$'\a' content
        # echo "$content"
        lines "$content"
    else
        lines "$1"; shift
    fi
    declare -i digits i=${#lines[*]}
    for (( ; i > 0; i /= 10 )); do (( ++digits)); done
    for line in "${lines[@]}"; do
        (( ++line_number ))
        echo "$(_style_lineno "$(printf %0${digits}i $line_number)") $line"
    done
}

function loadfn () 
{
    : @file 404 480 ~/usr/share/shlib/shlib-fn.bash
    : @uses init_usage usage_error base_getopts validate_file
    : @uses fn_location fn_depends fn_find_definition _store_for_file
    : @uses _bold_list _log _warn error_message _style_file linenos
    local Usage; init_usage<<EOF
[-h] [-f filename] fn1 [fn2 ...]

  Reloads the specified shell function(s) from the file specified by 
  '-f filename', if -f is provided, or from the file(s) noted in their
  provenance(s). If -f is not provided, and no provenance is available,
  the function will not be reloaded.
 
EOF
    local opt_file OPTIND;
    base_getopts "$Usage" "$@" || return $?;
    shift $((OPTIND-1));
    if [[ $# -eq 0 ]]; then
        usage_error "too few arguments" 1>&2;
        return 1;
    fi;
    local file fn fn_list definition tmp provenance_file;
    local TILDE='~';
    local -a provenance location vals visited_files fns=("$@") used=(`fn_depends ${fns[@]}`)
    Debug "(${fns[*]}) (${used[*]})"
    local -i i=0
    for fn in "${fns[@]}" "${used[@]}"; do
        location=( $(fn_location $fn) )
        local provenance_file="${location[*]:2}"
        if [ "$provenance_file" ]; then
            provenance_file=$(eval "echo $provenance_file");
        fi;
        if [[ "$opt_file" ]]; then
            file="$opt_file"
        else
            if [[ -n "$provenance_file" ]]; then
                file="$provenance_file";
            else
                file="$FUNCTION_FILE";
            fi;
        fi;
        if ! validate_file "$file" "$name"; then
            local RV=$?;
            [[ "$opt_file" ]] && return $RV;
            continue;
        fi;
        file="${file/$TILDE/$HOME}"
        _store_for_file "$file" $fn
    done
    tmp=""
    for (( i=0; i<${#visited_files[@]}; i++ )); do
        file="${visited_files[$i]}"
        fn_list="${vals[$i]}"
        local plural=""
        [[ "${fn_list// }" != "$fn_list" ]] && plural="s"
        definition="$( fn_find_definition "$file" $fn_list )";
        Debug "def:'$definition'"
        for fn in $fn_list; do
            if perl -e'$fn=shift;local $/;$_=<>;exit(m%^(function\s+$fn[\s({]|$fn\s*\(\)[\s{])%m?1:0)' "$fn" <<<$definition ; then
                error_message "couldn't find definition for function '$(_bold_list $fn)' in $(_style_file "$file")"
                tmp+=" $fn"
            fi
        done
        if [[ -n "$definition" ]]; then
            builtin source /dev/stdin <<<"$definition" # 2>/dev/null
            if ! graberr RV; then
                error_message "couldn't source definition for function$plural $(_bold_list $fn_list) from $(_style_file "$file"):"$'\n'"$(linenos "$definition")"
                return 5
            fi
            _log "from  $(_style_file $file):  loaded function$plural  $(_bold_list $fn_list)"
        else
            error_message "couldn't find definition for any function$plural $(_bold_list $fn_list) in $(_style_file "$file")"
        fi
    done
    [[ "$tmp" ]] && return 6 || return 0;
} ; complete -o filenames -F _loadfn loadfn
#; complete -o default -A function loadfn

function _loadfn() {
    : @file 483 493 ~/usr/share/shlib/shlib-fn.bash
    local -t context="$1" word="$2" prev_word="$3"
    ~dbg "$(declare -p -t)"
    if [ "$prev_word" = "-f" ]; then
        COMPREPLY=( $(compgen -o bashdefault -o default -o filenames "$word") )
        ~dbg "$(declare -p COMPREPLY)"
    else
        COMPREPLY=( $(compgen -W "-f -h" -A function "$word" ) )
    fi
}

# savefn saved on Wed Nov  6 22:04:03 PST 2019 to ~/usr/share/shlib/shlib.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.11(1)-release
function savefn () 
{
    : @file 496 621 ~/usr/share/shlib/shlib-fn.bash
    : @uses init_usage usage_error base_getopts validate_file
    : @uses fn_location update_line_numbers visit_file
    : @uses _log _style_file _bold_list
    local Usage; init_usage <<EOF
  [-h] [-f filename] fn1 [fn2 ...]

  Saves the  currently-defined shell functions named fn1 ... to the file
  specified by '-f filename', or to the file specified in its provenance, if
  one is present, or to the file specified by \$FUNCTION_FILE if -f is not
  given and no provenance is present.

  Any previous definition of the function in the file will be removed.
  Descriptive no-op lines (a provenance) will be injected into the beginning
  of the function body to describe where and when it was saved, what file it
  is sourced from, and the line # in that file where it can be found.
 
EOF
    local opt_file OPTIND;
    base_getopts "$Usage" "$@" || return $?
    shift $((OPTIND-1));
    if [[ $# -eq 0 ]]; then
        echo "Error: too few arguments" 1>&2;
        echo "$Usage" | head -1;
        return 1;
    fi;
    local -i i=0;
    local -a visited_files=();
    function delete_declaration () 
    { 
        local fn="$1" file="$2";
        perl -i -e'$/=undef; $_=<>; s%(?xms)
            [\s\n]* ^ \#
            ( \Q '"$fn"' \E )? saved .+?
            ^ \} [ \t]*
            ( ; [^\n]+? )* $
            [\s\n]*
            %\n\n%g; print' "$file";
        visit_file "$file"
    };
    local file name definition tmp provenance_file RV;
    local -a provenance;
    local IFS=$' ';
    local TILDE='~';
    local RV=0;
    for name in "$@";
    do
        Debug "'$name'"
        provenance=( `fn_location $name` )
        Debug "'$provenance'"
        provenance_file="${provenance[*]:2}"
        Debug "'$provenance_file'"
        if [[ -n "$provenance_file" ]]; then
            provenance_file=$(eval "echo $provenance_file");
            echo " $name is from $provenance_file";
            error_message " $(_bold_list $name) is from $(_style_file "$provenance_file")";
            delete_declaration "$name" "$provenance_file";
        fi;
        if [[ -n "$opt_file" ]]; then
            file="$opt_file"
        else
            if [[ -n "$provenance_file" ]]; then
                file="$provenance_file";
            else
                file="$FUNCTION_FILE";
            fi;
        fi;
        if ! validate_file "$file" "$name"; then
            RV=$?;
            [[ -n "$opt_file" ]] && break;
            continue;
        fi;
        delete_declaration "$name" "$file";
        provenance=("saved on $(date)");
        provenance+=("to ${file/$HOME/$TILDE}:#");
        provenance+=("from $(hostname)");
        provenance+=("  $(uname), $SHELL, $BASH_VERSION");
        local s EOP="________END_OF_PROVENANCE________";
        local -i l=0;
        for s in "${provenance[@]}"; do
            if [[ ${#s} -gt $l ]]; then
                l=${#s};
            fi;
        done;
        l+=5;
        tmp=\{$'\n';
        for s in "${provenance[@]}";
        do
            printf -v s "%-${l}s" "$s";
            tmp+="    : \" $s \""$'\n';
        done;
        tmp+="     : $EOP"$'\n';
        definition="$(declare -f -p "$name")";
        definition="${definition//$'\n'    true \"*true $EOP;$'\n'/$'\n'}";
        definition="${definition/\{/$tmp}";
        definition="${definition//\'$'\n'\'/\$\'\\n\'}";
        [[ -w $file ]] || touch $file;
        IFS=" ";
        local complete_stmt="$(complete -p $name 2>/dev/null)";
        if [[ $? -ne 0 ]]; then
            complete_stmt="";
        else
            complete_stmt=" ; $complete_stmt";
        fi
        local declare_stmt="$(declare -f -p $name | tail -1)";
        if [[ "$declare_stmt" =~ declare ]]; then
            declare_stmt=" ; $declare_stmt";
        else
            declare_stmt="";
        fi;
        echo >> "$file";
        echo "# $name ${provenance[*]}" >> "$file";
        echo "function $definition$declare_stmt$complete_stmt" >> "$file";
        echo >> "$file";
        _log "saved $(_bold_list $name) to $(_style_file "${file/$HOME/$TILDE}")";
        visit_file "$file";
    done;
    for file in "${visited_files[@]}";
    do
        update_line_numbers "$file";
    done;
    unset -f delete_declaration
    return $RV
} ; complete -o default -A function savefn

function croak ()
{
    : @file 623 632 ~/usr/share/shlib/shlib-fn.bash
    if [ $# -eq 0 ]; then
        return ${#croak_errors[*]}
    else
        echo "$*" >&2
        croak_errors+=( "$*" )
    fi
}

# editfn saved on Fri Apr 10 13:24:19 PDT 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.16(1)-release
function editfn () 
{
    : " saved on Fri Apr 10 13:24:19 PDT 2020                 "
    : " to ~/usr/share/shlib/shlib-fn.bash:635-647            "
    : " from rachels-mac.mei                                  "
    : "   Darwin, /usr/local/bin/bash, 5.0.16(1)-release      "
     : ________END_OF_PROVENANCE________
    : @file 635 647 ~/usr/share/shlib/shlib-fn.bash
    : @uses fn_location
    declare name="$1"
    local -a floc=($(fn_location "$name"))
    subl "${floc[2]}":${floc[0]}
} ; complete -o default -A function editfn
