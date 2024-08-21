# Configure a fancy prompt

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	   color_prompt=yes
    else
	   color_prompt=
    fi
fi

# °‘’“”⁻₋⸰__⸏⸐⸑⸐⸑⸐⸏⸏⸑ ⸐__⸑᰾𒑱𒑳𒑲𒑰⸫⁽₍⁾₎⁺⁻⁼ⁿ₊₋₌⋱⋆⋄∴∵∗∘∙∠∞∝ℵoא)╱╲─━─
export SUPERSCRIPT=( ⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹ ⁽ ⁾ ⁺ ⁻ ⁼ ⁿ )
export   SUBSCRIPT=( ₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉ ₍ ₎ ₊ ₋ ₌   )

function ~prompt_exitcode {
    local cmd=$1 S=$2
    if [ $cmd = color ]; then
        if [ $S -eq 0 ]; then
            return $S
        elif [ $S -lt 128 ]; then
            echo $'\e[00;31;01m'
        else
            echo $'\e[00;33;01m'
        fi
    elif [ $cmd = display ]; then
        if [ $S -lt 128 ]; then
            echo $S
        else
            echo "$(kill -l $((S-128)))"
        fi
    fi
    return $S
}

function ~prompt_path_original {
    : @uses fn_switch_identify_branches
    local -a switches branches; fn_switch_identify_branches
    local -a superscript=( ⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹ ⁿ )
    local color_working_dir=$'\e[38;5;27m'
    local color_branch=$'\e[1;4m'
    local color_end_branch=$'\e[22;24m'
    local color_footnotes=$'\e[0;36m'
    local END=$'\e[00m'
    local path
    local -i i
    for (( i=${#switches[@]}-1; i >= 0; --i )); do
    # for (( i=0; i < ${#switches[@]}; --i )); do
        local fragment="${switches[i]#${switches[i+1]:-}}"
        path+="${fragment%${fragment##*/}}"
        path+="$color_branch"
        path+="${fragment##*/}"
        path+="$color_end_branch"
        path+="$color_working_dir"
    done
    path+="${PWD#$switches}$END"
    echo -n "${color_working_dir}~/${path#~/}"
    for (( i=0; i<${#switches[@]}; ++i )); do
        echo -n " $color_footnotes${superscript[i+1]}$END"
        echo -n "$color_working_dir${branches[${#switches[@]} - 1 - i]}$END"
    done
    [ ${#switches[@]} -gt 0 ] && echo -n " "
}


function ~prompt_path {
    : @uses fn_switch_identify_branches
    : @file
    local -t cmd="$1"
    local -t -i pos="$2"
    local -t -a switches branches
    fn_switch_identify_branches
    local -t -i i=$(( ${#switches[*]} - pos ))
    ~dbg "$(declare -p -t)"
    case "$cmd" in
        (plain|hilit)
            local path
            if [ $i -eq -1 -a $cmd = 'plain' ]; then
                path="${PWD#${switches[0]}}"
            elif [ $i -ge 0 ]; then
                local fragment="${switches[i]#${switches[i+1]:-}}"
                local tail="${fragment##*/}"
                case "$cmd" in
                    (plain) path="${fragment%$tail}" ;;
                    (hilit) path="$tail" ;;
                esac
            fi
            [ $pos -eq 1 -a $cmd = 'plain' ] && path="${path/#$HOME/\~}"
            echo -n "$path" ;;
        (footnote)
            [ $i -ge 0 ] && echo -n " ${SUPERSCRIPT[pos]}"
            ;;
        (label)
            [ $i -ge 0 ] && echo -n "${branches[i]}"
            ;;
        *) echo "ERROR: bad cmd argument for $FUNCNAME">&2
    esac
}


tmp() {
    local i x a o
    if [ "$3" = '=' ]; then o=1
    else a=1
    fi
    local -a X=( $(cat "$1") )
    X=("${X[@]/%/\" ${a:+and}${o:+or} }")
    xpath -q -e '//dependency['"${X[*]/#/$4/text()${a:+\!}\=\"} "']/artifactId/text()' "$2" | sort | uniq
}

function ~dbg() {
    : #echo "$$:${BASH_SOURCE[2]}:${BASH_LINENO[1]}:${FUNCNAME[1]}: $*">>~/Debug
}

function __init_prompt {
    # iff SSH_TTY is set, display the host
    ##TODO: iff \u != EXPECTED_USER, display username
    local preamble='${debian_chroot:+($debian_chroot) }'

    local color_datetime="00;32"
    local color_user_at_host="32;01"
    local color_exitcode_alert="00;31;01"
    local color_signal_alert="00;33;01"
    local color_working_dir="[38;5;27m"
    local color_alerts="00;31"
    # local color_branch="\e[00;32m"

    local color_branch="[1;4m"
    local color_end_branch="[22;24m"
    local color_footnotes="[0;36m"

    local color
    [ "$color_prompt" = yes ] && color=yes
    local END
    [ $color ] && END="\[\e[00m\]"

    local datetime
    if [[ -z "$NO_DATETIME_PROMPT" ]]; then
        datetime="\d \t "
    fi

    local user_at_host
    if [ "$USER" != "$EXPECTED_USER" ]; then
        user_at_host+="\u"
        [ "$SSH_TTY" ] &&
            user_at_host+="@"
    fi
    [ "$SSH_TTY" ] &&
        user_at_host+="\h"
    if [ "$user_at_host" -a ! $color ]; then
        user_at_host+=":"
    fi

    # TODO: if TTY is in last from an iOS host, truncate path (just basename)
    # else, display the full path.
    local working_dir="\w"

    # echo -n '${_blank:= }${_blank#${_blank#
    #     ${_switches:=$(~prompt_switches)}
    #     ${_tmp:=fnop}
    # }}'
    # beginning stuff
    echo -n "$preamble"

    # timestamp
    [ $color ] && echo -n "\[\e[${color_datetime}m\]"
    echo -n "$datetime$END"

    # exit code
    [ $color ] && echo -n '\[$(~prompt_exitcode color $?)\]'
    [ $color ] && echo -n '$(~prompt_exitcode display $?)\[\e[00m\]'

    # spacer
    echo -n ' '

    # optionally user / hostname / user@hostname if any vary from default
    if [ "$user_at_host" ]; then
        [ $color ] && echo -n "\[\e[${color_user_at_host}m\]"
        echo -n "$user_at_host$END"
    fi

    if [ $color ]; then
        ## variable-length path display ...
        if true; then
        echo -n "\[\e$color_working_dir\]"
        local -i i
        for i in {1..3}; do
            echo -n "\$(~prompt_path plain $i)"
            echo -n "\[\e$color_branch\]"
            echo -n "\$(~prompt_path hilit $i)"
            echo -n "\[\e$color_end_branch\]"
        done
        for i in {1..3}; do
            echo -n "\[\e$color_footnotes\]"
            echo -n "\$(~prompt_path footnote $i)"
            echo -n "\[\e$color_working_dir\]"
            echo -n "\$(~prompt_path label $i)"
        done
        echo -n "$END"
        else
        echo -n '\[$(~prompt_path_original)\]'
        fi
    else
        echo -n "$working_dir$END"
    fi

    [ $color ] && echo -n "\[\e[${color_alerts}m\]"
    echo -n '${ALERTS[*]:+ ${ALERTS[*]}}'"$END"
    echo -n ' '
    echo '\$ '
}


PS1="$(__init_prompt)"
PS1_NOCOLOR="$(color_prompt=no; NO_DATETIME_PROMPT=1; __init_prompt)"
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
#    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\d \t \u@\h: \w\a\]$PS1"
    PS1="\[\e]0;${PS1_NOCOLOR}\a\]$PS1"
#    PS1="\[\e]7;file://\$HOSTNAME/\w\a\]$PS1"
    ;;
*)
    ;;
esac

