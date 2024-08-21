##
## TODO:
##
:<<'END_TODO'

END_TODO

if false; then
    echo " PPID=$PPID";
    echo " PID=$$";
    echo " BASHPID=$BASHPID";
    echo BASH_COMMAND="$X";
    echo " BASH_EXECUTION_STRING=\"$BASH_EXECUTION_STRING\"";
    echo " SHLVL=$SHLVL";
    echo " BASH_SUBSHELL=$BASH_SUBSHELL";
    ( echo BASH_SUBSHELL="\"$BASH_SUBSHELL\"";
    echo SHLVL=$SHLVL );
    echo " LINENO=$LINENO";
    set | egrep '^(FUNCNAME|BASH_(SOURCE|LINENO))=';
fi;

for _f in "$(dirname "${BASH_SOURCE}")"/shlib-{common,fn,utils{,-shared},linesets,switch}.bash; do
    source "$_f"
done
unset _f

# run_latest saved on Thu Jul 22 21:28:38 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.1.8(1)-release
function run_latest () 
{
    : " saved on Thu Jul 22 21:28:38 PDT 2021                "
    : " to ~/usr/share/shlib/shlib-tools.bash:28-41          "
    : " from rachels-mac.mei                                 "
    : "   Darwin, /usr/local/bin/bash, 5.1.8(1)-release      "
     : ________END_OF_PROVENANCE________
 
    local d="$(dirname "$1")";
    cd "$d";
    make "$(basename "$1")";
    cd - &> /dev/null;
    "$@"
} ; 

# dfh saved on Sun Apr 10 21:08:41 PDT 2022 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.1.8(1)-release
function dfh () 
{
    : " saved on Sun Apr 10 21:08:41 PDT 2022                "
    : " to ~/usr/share/shlib/shlib-tools.bash:44-54          "
    : " from rachels-mac.mei                                 "
    : "   Darwin, /usr/local/bin/bash, 5.1.8(1)-release      "
     : ________END_OF_PROVENANCE________
 
    : @file 44 54 ~/usr/share/shlib/shlib-tools.bash;
    df -PH | egrep 'Filesystem|/dev/disk1s1'
} ;


# dadjoke saved on Thu May 12 10:26:13 PDT 2022 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.1.8(1)-release
function dadjoke () 
{
    : " saved on Thu May 12 10:26:13 PDT 2022                "
    : " to ~/usr/share/shlib/shlib-tools.bash:58-69          "
    : " from rachels-mac.mei                                 "
    : "   Darwin, /usr/local/bin/bash, 5.1.8(1)-release      "
     : ________END_OF_PROVENANCE________
 
    : @file 58 69 ~/usr/share/shlib/shlib-tools.bash;
    curl https://icanhazdadjoke.com/;
    echo
} ; 
