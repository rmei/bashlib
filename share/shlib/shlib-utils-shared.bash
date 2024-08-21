function date_ () {
    : @file 1 4 ~/usr/share/shlib/shlib-utils-shared.bash
    date "$@" +%Y%m%dT%H%M%SZ
}

function _java_versions() {
    : @file 6 22 ~/usr/share/shlib/shlib-utils-shared.bash
    local -a versions=()
    declare version tmp
    for version in $(compgen -A variable JAVA); do
        version="${version#JAVA}"
        tmp="${version%_HOME}"
        if [ "$tmp" != "$version" ];
            then version="$tmp"
            # it's JAVA..._HOME
            # ignore if there's an internal underscore
            [ "${version/_}" != "$version" ] && continue
            versions+=( $version )
        fi
    done
    echo "${versions[@]}"
}

# usejava saved on Fri Oct 23 12:41:52 PDT 2020 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.16(1)-release
function usejava () 
{
    : @file 25 37 ~/usr/share/shlib/shlib-utils-shared.bash
    : @uses _java_versions

    declare ver="$1";
    local jhome="$(declare -p JAVA${ver}_HOME)";
    local newdecl="${jhome/JAVA${ver}_HOME/JAVA_HOME}";
    newdecl="JAVA_HOME=${newdecl#* JAVA_HOME=}";
    echo "jhome=$jhome" 1>&2;
    echo "newdecl=$newdecl";
    eval "$newdecl"
} ; complete -W "$(_java_versions)" usejava

# creds saved on Mon Mar  1 10:26:33 PST 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function creds () 
{
    : @file 40 53 ~/usr/share/shlib/shlib-utils-shared.bash
    : @uses _is_declared error_message
    local user=$USER profile=default domain="${1// }";
    if _is_declared -F "creds~$domain"; then
        "creds~$domain" "$@"
    elif _is_declared -F "~creds~$domain"; then
        "~creds~$domain" "$@"
    else
        error_message "could not locate domain-specific creds command either 'creds~$domain' or '~creds~$domain'"
        return 1
    fi
} ; 

# beep saved on Wed Oct 30 21:35:02 PDT 2019 to ~/usr/share/shlib/saved_functions.bash:# from debbox.mei   Linux, /bin/bash, 4.4.20(1)-release
function beep () 
{
    : @file 56 60 ~/usr/share/shlib/shlib-utils-shared.bash
    echo -n ''
}

function Beep () 
{
    : @file 62 67 ~/usr/share/shlib/shlib-utils-shared.bash
    : @uses beep
    echo -n ''
}

function D() {
    echo "$*" >&2
}

# in-place - saved Wed Jan 15 14:36:32 PST 2014
function in-place () {
    : @file 74 87 ~/usr/share/shlib/shlib-utils-shared.bash

    local _inplace_t="/tmp/inplace.$$.$RANDOM" _inplace_f="${!#}" _inplace_;
    for _inplace_ in "$@";
    do
        if [[ $_inplace_ =~ ^"\!" ]]; then
            _inplace_f="${_inplace_#\!}";
            break;
        fi;
    done;
    "${@#\!}" > "$_inplace_t";
    mv -f "$_inplace_t" "$_inplace_f"
}

function chunk ()
{
    : @file 89 110 ~/usr/share/shlib/shlib-utils-shared.bash
    : @uses _is_declared _is_array
    local -i batch_size=${CHUNK_BATCH:-2500}
    if ! _is_declared cmd; then
        local -a cmd
        if _is_array chunk; then
            cmd=( "${chunk[@]}" )
        elif _is_declared chunk; then
            cmd=( "$chunk" )
        else
            cmd=( $1 )
            shift
        fi
    fi
    local -a chunks=( "$@" )
    while [ "${#chunks[@]}" -gt $batch_size ]; do
        "${cmd[@]}" "${chunks[@]:0:$batch_size}"
        chunks=( "${chunks[@]:$batch_size}" )
    done
}

function xgrep () 
{ 
    : @file 112 141 ~/usr/share/shlib/shlib-utils-shared.bash
    : @uses require_var _warn chunk
    require_var xgrep_globs || return;
    local base="$1";
    local -i batch_size=${XGREP_BATCH:-2500}
    shift;
    local globopts=$(shopt -p nullglob);
    shopt -s nullglob;
    local -a globs
    eval "globs=( $xgrep_globs )"
    local -a excludes=( "${xgrep_excludes[@]/#/--exclude=}" )
    # for f in "${xgrep_excludes[@]}";
    # do
    #     excludes+=" --exclude=$f";
    # done;
    function _grep () 
    {
        # echo "egrep --color=auto --exclude-dir=.git ${excludes[*]} -n $*" >&2
        command egrep --color=auto --exclude-dir=.git "${excludes[@]}" -n "$@"
    };
    while [[ "${#globs[@]}" -gt $batch_size ]]; do
        _grep "$@" "${globs[@]:0:$batch_size}";
        globs=("${globs[@]:$batch_size}");
    done;
    _grep "$@" "${globs[@]}";
    unset -f _grep;
    eval "$globopts";
}

function require_var ()
{
    : @file 143 153 ~/usr/share/shlib/shlib-utils-shared.bash
    : @uses _is_declared error_message
    local v="$1"
    if ! _is_declared $v; then
        error_message 1 "must predeclare $(_bold_list $v)"
        return 1
    fi
    return 0
}

function xcat() {
    : @file 155 165 ~/usr/share/shlib/shlib-utils-shared.bash
    echo '<xcat xmlns="http://mei.gs/xcat/0.1.0">' # xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    local line
    local -a files
    while read line; do
        files+=("$line")
    done
    cat "${files[@]}" | command grep -v '<?xml '
    echo '</xcat>'
}

# git_untracked saved on Mon Sep 27 15:00:33 PDT 2021 to ~/usr/share/shlib/shlib-utils-shared.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.1.8(1)-release
function git_untracked () {
    : @file 168 172 ~/usr/share/shlib/shlib-utils-shared.bash
    local -i start=2+$( git status | grep -n 'Untracked files:' | cut -d: -f1 )
    git status | tail +$start | head -$(( $(git status | wc -l ) - 1 - start ))
}
