##
## TODO:
##
:<<'END_TODO'

END_TODO


# _pushd - saved Mon Jan 13 11:43:06 PST 2014
function _pushd () 
{ 
    : @file 10 14 ~/usr/share/shlib/shlib-utils.bash
    pushd "$@" > /dev/null
}

# _popd - saved Mon Jan 13 11:43:10 PST 2014
function _popd () 
{
    : @file 17 21 ~/usr/share/shlib/shlib-utils.bash
    popd "$@" > /dev/null
}

# listen saved on Thu Oct 17 12:47:11 PDT 2019 to usr/share/shlib/saved_functions.bash:# from debbox.mei      Linux, /bin/bash, 4.4.20(1)-release
function listen () 
{
    : @file 24 42 ~/usr/share/shlib/shlib-utils.bash
    local -x pattern="$1" input_file="$2" interval="${3:-10}"
    local -x tmpfile="/tmp/$FUNCNAME.$$" output_file="$pattern.log";
    local -x -i MATCH NEXT BEGIN=1;
    while true; do
        NEXT=$(wc -l < "$input_file")
        if tail -n +$BEGIN "$input_file" | grep -n "$pattern" > "$tmpfile"; then
            MATCH=$(tail -1 < "$tmpfile" | cut -d: -f1)
            NEXT=$((BEGIN + MATCH));
            echo -n '' 1>&2;
            echo " _____ $(date) _____ (from: $BEGIN) _____";
            cat "$tmpfile";
        fi;
        BEGIN=$NEXT
        sleep "$interval";
    done | tee "$output_file"
}

# saved on Mon Nov  11 16:25:00 PST 2019 to ~/usr/share/shlib/shlib.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 4.4.19(1)-release
function ugrep () 
{
    : @file 45 55 ~/usr/share/shlib/shlib-utils.bash
     : @uses xgrep
    local xgrep_globs
    local -a xgrep_excludes
    local BASE=~/usr;
    xgrep_globs='$HOME/usr{,/{arch,site,local}}/{etc,share/shlib}/*' # {,/*{,/*}}
    xgrep_excludes=( );
    xgrep "$BASE" --directories=recurse "$@"
}

# watchfile saved on Thu Jan  9 11:19:13 PST 2020 to ~/usr/share/shlib/shlib.bash:# from debbox.mei      Linux, /bin/bash, 4.4.20(1)-release
function watchfile () 
{
    : @file 58 76 ~/usr/share/shlib/shlib-utils.bash
    local L f="$1" t="$3";
    local -i period="$2" accumulated=0 interval=5;
    [[ -n $t ]] || t=`date`;
    echo -n "$t  ";
    lsof "$f" 2> /dev/null | tail -1;
    while L=`lsof "$f" 2>/dev/null`; do
        sleep $interval;
        accumulated+=$interval;
        if [[ $accumulated -ge $period ]]; then
            accumulated=0;
            t=`date`;
            L="$(echo "$L" | tail -1)";
            echo "$t  $L";
        fi;
    done
} ; complete -F _minimal watchfile

# st2 - saved Fri Jul  7 16:38:20 PDT 2017
function st () 
{
    : @file 79 84 ~/usr/share/shlib/shlib-utils.bash
    : "should probably go under arch (darwin)"
    open -a "Sublime Text" "$@"
}

# In saved on Fri Mar 13 14:35:43 PDT 2020 to ~/usr/share/shlib/shlib-tools.bash:# from debbox.mei      Linux, /bin/bash, 4.4.20(1)-release
function In () 
{
    : @file 87 95 ~/usr/share/shlib/shlib-utils.bash
    local d="$1";
    shift;
    pushd "$d" > /dev/null;
    "$@";
    popd > /dev/null
} ; complete -F _minimal In


# git_shove saved on Fri Mar 13 14:55:54 PDT 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.11(1)-release
function git_shove () 
{
    : " saved on Fri Mar 13 14:55:54 PDT 2020                 "
    : " to ~/usr/share/shlib/shlib-utils.bash:99-111          "
    : " from rachels-mac.mei                                  "
    : "   Darwin, /usr/local/bin/bash, 5.0.11(1)-release      "
     : ________END_OF_PROVENANCE________
 
    : @file 99 111 ~/usr/share/shlib/shlib-utils.bash
    git commit -am"${1:-$0 $*}";
    [ $? == 0 ] && git push;
    true
} ; 

# alert_when_done saved on Mon Mar 30 01:25:52 PDT 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.16(1)-release
function alert_when_done () 
{
    : @file 114 127 ~/usr/share/shlib/shlib-utils.bash
    declare -i pid="$1";
    while true; do
        sleep 1;
        if ps -p "$pid" &> /dev/null; then
            :;
        else
            echo '';
            break;
        fi;
    done
} ; 

function silently ()
{
    : @file 129 136 ~/usr/share/shlib/shlib-utils.bash
    declare -i retval
    __="$("$@" 2>&1)"
    _silently_returned=$?
    return $_silently_returned
}

function tf ()
{
    : @file 138 244 ~/usr/share/shlib/shlib-utils.bash
    : @uses silently croak
    :<<-"EOF"
        tf -defs [ -{B|D|E} ___ ]... [ filename ]

        tf -B (/tmp) # tf_base / root dir of temp workspace
      * tf +d # put tempfile in $tf_base
        tf -d # generate a dirname, create it, put tempfile inside it
        #TODO: tf -D ${1:-{use_scriptname:-${use_funcname}}
        tf temporary.properties (implies -d)
     # only if generating filename
        tf -e ${1:-${TF_EXT:-tmp}}
        tf -E # no extension
        tf -f # if generating name, generate from funcname
        tf -s # if generating name, generate from scriptname
EOF
    declare -t ext_none=" - " ext_default="${TF_EXT:-tmp}" base_default=/tmp
    # Defaults
    declare -t use_funcname use_scriptname use_subdir ext filename
    declare -t base="$base_default" delete_on_return=1
    declare -t -i export_to_frame=1
    declare -t tf_opt OPTARG OPTIND
    while getopts "b:dD:e:Efksh" tf_opt; do
        case "$tf_opt" in
            b) base="$OPTARG" ;;
            d) use_subdir=1 ;;
            # D) ;;
            e) ext="$OPTARG" ;;
            E) ext="$ext_none" ;;
            f) use_funcname=1 ;;
            F) filename="$OPTARG" ;;
            k) delete_on_return="" ;;
            s) use_scriptname=1 ;;
            v) echo "$OUR-$VERSION" ; return 0 ;;
            h|H) usage_$FUNCNAME $tf_opt ; return 0 ;;
            *) usage_$FUNCNAME $tf_opt ; return 1 ;;
        esac
    done
    shift $(( OPTIND - 1 ))
    declare -t filename="$1"
    declare -t funcname scriptname
    # Calculated Defaults
    if [ -z $use_scriptname -a -z $use_funcname ]; then
        use_funcname=1
        funcname="${FUNCNAME[export_to_frame]:-${BASH_SOURCE[export_to_frame]:-$0}}"
    fi
    [ $use_funcname ] &&
        funcname="${FUNCNAME[export_to_frame]}"
    [ $use_scriptname ] &&
        scriptname="${BASH_SOURCE[export_to_frame]:-$0}"
    declare -t id="$$_$BASHPID"
    declare -t name_generated="${funcname:-$scriptname}-$id"
    declare -t dirname="${use_subdir:+$name_generated}"
    declare -t dir="$base"${use_subdir:+/}"${use_subdir:+dirname}"
    ext="${ext:-$ext_default}"
    [ "$ext" = "$ext_none" ] &&
        ext=""
    declare -t filename_generated="$name_generated${ext:+.}$ext"
    declare -t file="$dir"/"${filename:-$filename_generated}"

    declare -t -a croak_errors

    [ $# -gt 1 ] &&
        croak "too many arguments to $FUNCNAME: $#"
    [ "$use_scriptname" -a "$use_funcname" ] &&
        croak "only one of -f or -s may be specified"
    [ -e "$base" -a ! -d "$base" ] &&
            croak "'$base' is not a directory; specify a valid base directory with -b"
    [ ! -e "$base" ] &&
        croak "'$base' does not exist; specify a valid base directory with -b"
    if [ $use_subdir ]; then
        [ -e "$dir" -a ! -d "$dir" ] &&
            croak "'$dir' already exists and is not a directory: refusing to continue"
    fi
    [ -f "$file" ] &&
        croak "'$file' already exists: refusing to continue"
    [ -e "$file" -a ! -f "$file" ] &&
        croak "'$file' already exists and is not a regular file: refusing to continue"
    croak || {
        echo "$? errors" >&2
        declare -p -t
        return $BASH_LINENO
    }

    # do the work
    if [ "$use_subdir" -a ! -e "$dir" ]; then
        silently mkdir -p "$dir" || { croak "mkdir -p \"$dir\" failed: $__" && return $BASH_LINENO ; }
    fi
    tf="$file"
    # if [ $delete_on_return ]; then
    #     declare -t cleanup_fn="_tf_${funcname}_${id}" target="${use_subdir:+$dir}"
    #     target="${target:-$file}"
    #     declare -t -i depth=${#FUNCNAME[*]}
    #     eval "$cleanup_fn () {
    #         if [ \${#FUNCNAME[*]} -eq $depth -a \"\${FUNCNAME[$export_to_frame]}\" == '$fun' ]; then
    #             rm -fr '$target' &>/dev/null
    #             unset -f $cleanup_fn
    #             trap - RETURN
    #         fi
    #     }"
    #     trap "$cleanup_fn" RETURN
    # fi
    silently touch "$file" || { croak "touch \"$file\" failed: $__" && return $BASH_LINENO ; }
    return 0
}


function pidtree () {
    : @file 247 284 ~/usr/share/shlib/shlib-utils.bash
    declare -t -i pid ppid pgid
    declare -t command
    declare -t -a pids ppids pgids commands
    #ps -opid= -oppid= -opgid= > tmp.txt
    while read -u 17 pid ppid pgid command; do
        #echo "'$pid' '$ppid' '$pgid'"
        pids+=( $pid )
        ppids[pid]=$ppid
        pgids[pid]=$pgid
        commands[pid]="$command"
    done 17< <(ps -opid= -oppid= -opgid= -ocommand=)

    declare -t -a children
    for pid in "${pids[@]}"; do
        children[ppids[pid]]+="$pid "
    done

    declare -t -i top
    declare -t -a stack=( $1 )
    declare -t tmp tree indent step=$'  '
    while [ $stack ]; do
        (( top = ${#stack[*]} - 1 ))
        tmp=${stack[top]} # peek
        unset stack[top] # pop
        pid=$tmp
        indent="${tmp%$pid}"
        tree+="$tmp"$'\n'
        # tree+="  "$'\t'"${commands[pid]}"
        if [ "${children[pid]+haschildren}" == 'haschildren' ]; then
            for pid in ${children[pid]}; do
                stack+=( "$indent$step$pid" )
            done
        fi
    done
    echo -n "$tree"
}

function killtree () {
    : @file 286 293 ~/usr/share/shlib/shlib-utils.bash
    : @uses pidtree
    declare -t -i pid="$1"
    declare -t -a descendents=( $(sort -n -r <<<"$(pidtree $pid)") )
    echo "\$ kill ${descendents[*]}"
    kill ${descendents[@]} #&>/dev/null
}

# sudo_preserve saved on Thu Apr  9 17:21:30 PDT 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.16(1)-release
function sudo_preserve () 
{
    : @file 296  ~/usr/share/shlib/shlib-utils.bash
    local -i minutes=$1 seconds=0;
    echo "current seconds: $seconds    minutes to preserve: $minutes">&2
    [ $seconds -lt $((minutes * 60)) ] && sudo -v
    sudo_preserver() {
        for ((1; seconds < minutes * 60 ; seconds+=60 )); do
            sudo -v
            sleep 60
        done
        echo "*** NO LONGER PRESERVING SUDO AUTH ($minutes minutes have passed) ***" >&2
        echo $'\a\a\a' >&2
    }
    coproc _sudo_preserver { sudo_preserver; }
}

# git-dupe saved on Mon Nov  2 11:47:17 PST 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.16(1)-release
function git-dupe () 
{
    : @file 314 325 ~/usr/share/shlib/shlib-utils.bash
    ( while [ ! -d .git ]; do
        cd ..;
    done;
    r="$(basename "$PWD")";
    cd ..;
    dr=".$r-$(date +%Y%m%d)";
    rm -fr "$dr";
    cp -R "$r" "$dr" )
} ; 


# git-restore saved on Mon Nov  2 11:47:17 PST 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.16(1)-release
function git-restore () 
{
    : @file 329 342 ~/usr/share/shlib/shlib-utils.bash
    local pwd="$PWD";
    while [ ! -d .git ]; do
        cd ..;
    done;
    local repo="$(basename "$PWD")";
    cd ..;
    backup=".$repo-$(date +%Y%m%d)";
    rm -fr "$repo";
    cp -R "$backup" "$repo";
    cd "$pwd"
} ; 

# chunk saved on Wed Mar 10 11:29:20 PST 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function chunk () 
{
    : @file 345 368 ~/usr/share/shlib/shlib-utils.bash
    : @uses _is_declared _is_array;
    local -i batch_size=${CHUNK_BATCH:-3000};
    if ! _is_declared cmd; then
        local -a cmd;
        if _is_array chunk; then
            cmd=("${chunk[@]}");
        else
            if _is_declared chunk; then
                cmd=("$chunk");
            else
                cmd=($1);
                shift;
            fi;
        fi;
    fi;
    local -a chunks=("$@");
    while [ "${#chunks[@]}" -gt $batch_size ]; do
        "${cmd[@]}" "${chunks[@]:0:$batch_size}";
        chunks=("${chunks[@]:$batch_size}");
    done
} ; 

# sumlines saved on Wed Mar 10 10:53:53 PST 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function sumlines () 
{
    : @file 371 375 ~/usr/share/shlib/shlib-utils.bash
    perl -MM -e 'for (slurp) { @f=split/\t/; $sum+=$f[0]; } P $sum' "$@"
} ;

# dfind saved on Wed Mar 24 10:34:08 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function dfind () {
    : @file 378 412 ~/usr/share/shlib/shlib-utils.bash
    : @uses init_usage usage_error ~dbg
    ~dbg "$#: '$*'"
    local Usage;
    init_usage <<EOF
 [dirname ...] [ [#min] #max ] [<find options> ...]
  If no dirnames are provided, assumes "."
EOF
    ~dbg "$#: '$*'"
    [ $# -eq 0 ] && { usage_error 2 "too few options" ; return 1; }
    local -a path
    local min max
    while [[ $# -gt 0 && ! "$1" =~ ^[0-9]+([-,][0-9]*)?$ ]]; do
        path+=("$1")
        shift
    done
    # assume '.' if no directories provided
    [ ${#path[*]} -eq 0 ] && path+=('.')
    [ $# -eq 0 ] && { usage_error 2 "too few options" ; return 2; }
    if   [[ "$1" =~ ^([0-9]+)[-,]([0-9]+)?$ ]]; then
        min=${BASH_REMATCH[1]}
        max=${BASH_REMATCH[2]}
        shift
    elif [[ "$1" = +([0-9]) ]]; then
        max=$1
        shift
        if [[ "$1" = +([0-9]) ]]; then
            min=$max
            max=$1
            shift
        fi
    fi
    find "${path[@]}"${min:+ -mindepth $min}${max:+ -maxdepth $max} "$@"
} ; 

# # xpath saved on Wed Mar 31 02:52:01 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
# function xpath () 
# {
#     : @file 435 439 ~/usr/share/shlib/shlib-utils.bash
#     command xpath "$@" 2> /dev/null
# } ; 

# p4field saved on Mon May 24 10:55:01 PDT 2021 to ~/usr/share/shlib/shlib-utils.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function p4field () 
{
    : @file 422 435 ~/usr/share/shlib/shlib-utils.bash
    local -t field="$1";
    shift;
    local -t -a opts;
    while [ "${1:0:1}" = "-" ]; do
        opts+=("$1");
        shift;
    done;
    local -t command="$1";
    shift;
    p4 "${opts[@]}" "$command" "$@" | perl -e'while(<>){$p=0 if /^\S/;$p=1 if /^'"$field"'/i;print if $p && /\S/}'
} ; 

# uniq() {
#     : @file 457 460 ~/usr/share/shlib/shlib-utils.bash
#     ~/usr/bin/uniq "$@"
# }


# loglisten saved on Fri Sep 30 10:30:37 PDT 2022 to ~/usr/share/shlib/shlib-utils.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.1.16(1)-release
function loglisten () 
{
    : " saved on Fri Sep 30 10:30:31 PDT 2022                 ";
    : " to ~/usr/share/shlib/shlib-utils.bash:444-458         ";
    : " from rachels-mac.mei                                  ";
    : "   Darwin, /usr/local/bin/bash, 5.1.16(1)-release      ";
    : ________END_OF_PROVENANCE________;
    : @file 444 458 ~/usr/share/shlib/shlib-utils.bash;
    local f;
    for f in "$@";
    do
        export f;
        ( tail -F -1 "$f" | prefix "$f" ) &
    done
} ;


# reconcile_timestamp saved on Mon Oct  9 16:49:55 PDT 2023 to ~/usr/share/shlib/shlib-utils.bash:# from Rachels-Mac-mini.local   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release
function reconcile_timestamp () 
{
    : " saved on Mon Oct  9 16:49:55 PDT 2023                    "
    : " to ~/usr/share/shlib/shlib-utils.bash:462-476            "
    : " from Rachels-Mac-mini.local                              "
    : "   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release      "
     : ________END_OF_PROVENANCE________
 
    : @file 462 476 ~/usr/share/shlib/shlib-utils.bash;
    : @uses _reconcile_timestamp;
    local target
    for target in "$@"; do
        _reconcile_timestamp "$target"
    done
} ; 


# _reconcile_timestamp saved on Mon Oct  9 16:49:55 PDT 2023 to ~/usr/share/shlib/shlib-utils.bash:# from Rachels-Mac-mini.local   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release
function _reconcile_timestamp () 
{
    : " saved on Mon Oct  9 16:49:55 PDT 2023                    "
    : " to ~/usr/share/shlib/shlib-utils.bash:480-493            "
    : " from Rachels-Mac-mini.local                              "
    : "   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release      "
     : ________END_OF_PROVENANCE________
 
    : @file 480 493 ~/usr/share/shlib/shlib-utils.bash;
    : @uses _find_timestamp_source;
    local target="$1";
    local source="$(_find_timestamp_source "$target")";
    touch -r "$source" "$target"
} ; 


# _find_timestamp_source saved on Mon Oct  9 16:49:55 PDT 2023 to ~/usr/share/shlib/shlib-utils.bash:# from Rachels-Mac-mini.local   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release
function _find_timestamp_source () 
{
    : " saved on Mon Oct  9 16:49:55 PDT 2023                    "
    : " to ~/usr/share/shlib/shlib-utils.bash:497-517            "
    : " from Rachels-Mac-mini.local                              "
    : "   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release      "
     : ________END_OF_PROVENANCE________
 
    : @file 497 517 ~/usr/share/shlib/shlib-utils.bash;
    : @uses _reconcile_timestamp _get_timestamp_source;
    local dir="${1%/}";
    local file="$(_get_timestamp_source "$dir")";
    if [[ "$dir" == "$file" ]]; then
        for file in $(ls -F "$dir" | grep -e '/$');
        do
            _reconcile_timestamp "$dir/${file%/}";
        done;
        file="$(_get_timestamp_source --dirs "$dir")";
    fi;
    echo "$file"
} ; 


# _get_timestamp_source saved on Mon Oct  9 16:49:55 PDT 2023 to ~/usr/share/shlib/shlib-utils.bash:# from Rachels-Mac-mini.local   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release
function _get_timestamp_source () 
{
    : " saved on Mon Oct  9 16:49:55 PDT 2023                    "
    : " to ~/usr/share/shlib/shlib-utils.bash:521-540            "
    : " from Rachels-Mac-mini.local                              "
    : "   Darwin, /opt/homebrew/bin/bash, 5.2.15(1)-release      "
     : ________END_OF_PROVENANCE________
 
    : @file 521 540 ~/usr/share/shlib/shlib-utils.bash;
    local dir="$1";
    local pattern="|/=";
    if [[ "$dir" == "--dirs" ]]; then
        pattern="|=";
        shift;
        dir="$1";
    fi;
    pattern='['"$pattern"']$';
    local file="$(ls -tF "$dir" | grep -v -e "$pattern" | head -1)";
    echo "${dir%/}${file:+/${file%/}}"
} ; 
