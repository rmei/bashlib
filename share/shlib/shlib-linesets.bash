##
## TODO:
##
:<<'END_TODO'

END_TODO

# disjunction saved on Wed Mar 31 03:05:42 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function disjunction () 
{
    : @file 9 19 ~/usr/share/shlib/shlib-linesets.bash
    : @uses 
 
    local a="$1" b="$2";
    { 
        sort "$a" | uniq;
        sort "$b" | uniq
    } | sort | uniq -c | command grep -E '^ *1 ' | cut -d1 -f2- | cut -d' ' -f2-
} ; 

# ~set~difference saved on Wed Mar 31 03:19:50 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function ~set~difference () 
{
    : @file 22 27 ~/usr/share/shlib/shlib-linesets.bash
    : @uses ~set~disjunction ~set~intersection
    ~set~disjunction "$1" <(~set~intersection "$1" "$2")
} ; 


# ~set~disjunction saved on Wed Mar 31 03:19:50 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function ~set~disjunction () 
{
    : @file 31 37 ~/usr/share/shlib/shlib-linesets.bash
    : @uses ~set~~venn
 
    ~set~~venn "$1" "$2" 1
} ; 


# ~set~intersection saved on Wed Mar 31 03:19:50 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function ~set~intersection () 
{
    : @file 41 47 ~/usr/share/shlib/shlib-linesets.bash
    : @uses ~set~~venn
 
    ~set~~venn "$1" "$2" 2
} ; 


# ~set~~venn saved on Wed Mar 31 03:19:50 PDT 2021 to ~/usr/share/shlib/shlib-tools.bash:# from rachels-mac.mei   Darwin, /usr/local/bin/bash, 5.0.18(1)-release
function ~set~~venn () 
{
    : @file 51 58 ~/usr/share/shlib/shlib-linesets.bash
    { 
        sort "$1" | uniq;
        sort "$2" | uniq
    } | sort | uniq -c | command grep -E '^ *'"$3"' ' | cut -d"$3" -f2- | cut -d' ' -f2-
} ; 
