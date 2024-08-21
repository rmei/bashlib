#!/bin/bash

shopt -s extglob

declare HERE="$(cd "$(dirname "$BASH_SOURCE")";pwd;cd - &>/dev/null)"
builtin source "$HERE"/setup.config

if [[ -f ~/.eyrierc ]]; then
    builtin source ~/.eyrierc
fi

# TODO: need to check PRIMARY_CLOUD and IN_* to find .../share
declare SHARE="$(cd "$HERE"/../share;pwd;cd - &>/dev/null)"
builtin source "$SHARE"/shlib/shlib-basic-cli.bash

declare -a supported_clouds=( Dropbox Drive iCloud )
###  PATHCONSTANTS  ###

# Path components / important tokens
declare -r USR="${USR_RELATIVE:+usr}"
declare -r LOCAL="${LOCAL_RELATIVE:+local}"

declare -r DRIVE=Drive
declare -r DROPBOX=Dropbox
declare -r ICLOUD=iCloud

declare -r DRIVE_ABS="$DRIVE_HOME/$DRIVE_RELATIVE"
declare -r DROPBOX_ABS="$DROPBOX_HOME/$DROPBOX_RELATIVE"
declare -r ICLOUD_ABS="$ICLOUD_HOME/$ICLOUD_RELATIVE"


declare -r ANCHOR=._

# Absolute Paths
declare -r USR_ABS="$HOME/$USR"
declare -r LOCAL_ABS="$USR_ABS/$LOCAL_RELATIVE"

# Key Locations
declare -r LOCAL_CONFIG_BACKUP="$LOCAL/etc/original"
declare -r LOCAL_PIP_BACKUP="$USR/var/pip/original"
declare -r LOCAL_CPAN_BACKUP="$USR/var/cpan/original"

## TODO: validate these as well ...
# GOOGLE_DRIVE_RELATIVE
# DROPBOX_RELATIVE
# GOOGLE_DRIVE_HOME
# DROPBOX_HOME

# Lists

declare -a FHS_LINKED=( bin etc home lib opt sbin share )
declare -a PATH_PRIORITY_ASC=( $(echo "$USR"{,/{arch,site{,/arch},local}}) )
declare -a FHS_CONCRETE=( var/cpan $(compgen -P "$LOCAL"/ -W "var ${FHS_LINKED[*]}") )
declare -a GLOBAL_PATH_PRIORITY_ASC=( "" /usr /usr/local $(compgen -P "$HOME"/ -W "${PATH_PRIORITY_ASC[*]}") )
declare -a ARGS=("$@")

export -f run_if_present
export -f report reportd
export -f get_display_path

export -f desym
export -f normalize

export -f link_to

D() {
    [ -n "$_SETUP_DEBUG" -a "$_SETUP_DEBUG" != 0 ] && echo "$@">&2;
} ; export -f D

for arg in "$@"; do
    if [[ "$arg" =~ ^(-v|--verbose)$ ]]; then
        export _VERBOSE=1
    elif [[ "$arg" =~ ^(--debug)$ ]]; then
        echo "FOOBIE BLETCH" >&2
        export _SETUP_DEBUG=1
    fi
done



:<<'Precedence_MD'

# General Hierarchies of Precedence

( ~/usr == Eyrie root )

    ~
    ~/usr/local
    ~/usr/site/arch
    ~/usr/site
    ~/usr/arch
    ~/usr
    /usr/local
    /usr/site
    /usr
    /

## Expected Hierarchical Processing Patterns

1. FHS Inheritance.

The effective config = a layering of all visible configs following FHS order: "most specific composited"

example: `.gitconfig`

2. Ancestral Inheritance

The effective config = a layering of all visible configs in the directory path-to-root: "mine + parent's + grandparent's + ..."

example: `.p4config`



## Specific Handling for various subsystems

Considering the FHS, there are several expected precedence-order behaviors.

etc

    ~/.* (usually symlinked to ~/usr{...}/etc/*)
    ~/usr/local/etc
    ~/usr/site/arch/etc
    ~/usr/site/etc
    ~/usr/arch/etc
    ~/usr/etc

PATH

    ~/sbin
    ~/bin
    ~/usr/local/sbin
    ~/usr/local/bin
    ~/usr/site/arch/sbin
    ~/usr/site/arch/bin
    ~/usr/site/sbin
    ~/usr/site/bin
    ~/usr/arch/sbin
    ~/usr/arch/bin
    ~/usr/sbin
    ~/usr/bin
    /usr/local/sbin
    /usr/local/bin
    /usr/sbin
    /usr/bin
    /sbin
    /bin


Precedence_MD






 ###################/
###################/
###
###  Begin Configuration
###
###############/
 #############/

if [[ -r "$HOME"/.eyrie-setuprc ]]; then
    builtin source "$HOME"/.eyrie-setuprc
fi

if [[ -z "$EYRIE_SITE" -a -n "$DETECTED_SITE" ]]; then
    D "DETECTED_SITE=$DETECTED_SITE"
    declare EYRIE_SITE="$DETECTED_SITE"
fi

#TODO: *correctly*/*robustly* determine whether dropbox is installed & running

# if false; then
# if which dropbox; then
#     until dropbox running; do
#         report error "dropbox commandline util found, but no dropbox service is running!"
#         exit 1
#     done
# elif which dropbox.py; then
#     until dropbox.py running; do
#         report error "dropbox.py found, but no dropbox service is running!"
#         exit 1
#     done
# else
#     report warn "Couldn't find Dropbox in \$PATH; cautiously continuing."
# fi
# fi

#TODO: determine whether Google Drive is needed / installed / running

# set-up arch and site directories
os=$(uname -s | awk '{print tolower($0)}')
if [[ $os == darwin ]]; then
    true ; # nothing special to do yet
elif [[ $os == linux ]]; then
    if [[ "$(uname -a)" =~ [Uu]buntu|[Dd]ebian ]]; then
        os=debian
    else
        report warn "Don't recognize this flavor of Linux (\"$(uname -a)\") as one we support, but hoping for the best ..."
        os=debian
    fi
elif [[ $os == cygwin ]]; then
    report warn "Wow! Cygwin? Optimistic, but okay, we'll try ..." >&2
elif [[ $os == win32 || $os == mingw32 ]]; then
    # Nope.
    report error "\"$os\" is not supported. Take a look at \"$BASH_SOURCE\" for details. " >&2
    exit 2
else # unrecognized OS ...
    report error "Don't recognize OS \"$os\" ... cowardly refusing to continue."
    exit 2
fi

report info "using os=\"$os\""

# this is the default; we'll consider refining it later on
arch=$os

#TODO: cloud root relative position needs to be configurable. Need some sort of selective-sync config. Probably use .eyrie-setuprc

declare -a used_clouds=( $PRIMARY_CLOUD )
for cloud in "${supported_clouds[@]}"; do
    D "identifying dirs hosted in $cloud"
    uccloud="$(uc $cloud)"
    if isset IN_${uccloud}; then
        D "$(declare -p IN_$uccloud)"
        used_clouds+=( $cloud )
        unset _IN_TMP
        if copy_var IN_${uccloud} _IN_TMP; then
            # D "$(declare -p _IN_TMP)"
            for dir in "${_IN_TMP[@]}"; do
                declare _IN_${uccloud}_$dir
            done
        else
            report warn "problem allocating dirs via IN_${uccloud}; skipping."
        fi
    elif [ $cloud = $PRIMARY_CLOUD ]; then
        D "$(declare -p cloud)"
        copy_var "${uccloud}_ABS" cloudpath
        for dir in $os $DETECTED_SITE; do
            if [ -d "$cloudpath/$dir" ]; then
                D "found $dir in $cloud"
                declare _IN_${uccloud}_$dir
            fi
        done
    fi
done

# set-up any special os handling
for cloud in "${used_clouds[@]}"; do
    uccloud="$(uc $cloud)"
    D "checking $cloud for special handling for $os"
    if isset _IN_${uccloud}_${os}; then
        D "found $os in $cloud"
        unset cloudpath
        copy_var "${uccloud}_ABS" cloudpath
        D "$(declare -p cloudpath)"
        # platform-specific setup
        if refine_arch="$(run_if_present $cloudpath/$os/sbin/setup-$os.bash refine_arch)"; then
            arch="$refine_arch"
        fi
    fi
done


 ###################/
###################/
###
###  Begin FS Modification
###
###############/
 #############/

echo "Setting-up ~/$USR/..."

# create the local tree, FIRST, so we've somewhere to back things up
cd "$HOME"
makedir "$USR"
makedir "$ANCHOR"

pushd "$USR" >/dev/null
mkdir -p "${FHS_CONCRETE[@]}"

report info "using arch=\"$arch\""
[[ -e arch ]] || ln -s $arch arch

#TODO: need a better way of autodetecting site.
site=$DETECTED_SITE
report info "using site=\"$site\""
[[ -e site ]] || ln -s $site site

[[ -e var/.$site-arch ]] || ln -s ../$site/$arch var/.$site-arch

# 
# setup_cloud_dir $NAME $SVC_HOME $SVC_RELATIVE will ...
#   - put a link at $USR/var/$NAME.root pointing to $SVC_HOME
#   - put a link at $USR/var/$NAME pointing to $SVC_HOME/$SVC_RELATIVE
#   - put a link at $SVC_HOME/$SVC_RELATIVE/._ pointing to $SVC_HOME/../._
#   - put a link at $SVC_HOME/../._ pointing to ~/._ (unless the two are the same dir)
# 
function setup_cloud_dir () {
    declare -t service_name="$1" service_home="$2" service_relpath="$3"
    declare var="$USR_ABS"/var
    declare -t anchor_parent="$(dirname "$service_home")"
    declare -t ln_path="$(relativize "$service_home/$service_relpath" "$anchor_parent")"
    [ "$(normalize "$anchor_parent" .)" != "$HOME" ] && link_to "$HOME/$ANCHOR" "$anchor_parent/$ANCHOR"
    link_to "$ln_path/$ANCHOR" "$service_home/$service_relpath/$ANCHOR"
    # create var symlinks to sharing services
    declare -r path_from_var="$(relativize "$var" "$service_home")"
    link_to "$path_from_var" "$var"/"$service_name".root
    link_to "$service_name".root/"$service_relpath" "$var"/"$service_name"
}

function cloud_error_display () {
    local cloud="$1" var="$2" txt="$cloud is selected but can't understand"
    echo "$txt var $var = $(quoted_val $var) -- Skipping ..."
}

echo "$(uc Foo)"
for cloud in "${used_clouds[@]}"; do
    uccloud="$(uc $cloud)"
    copy_var ${uccloud} service_name
    [ $? -ne 0 ] && report warn "$(cloud_error_display $cloud ${uccloud})" && continue
    copy_var ${uccloud}_HOME service_home
    [ $? -ne 0 ] && report warn "$(cloud_error_display $cloud ${uccloud}_HOME)" && continue
    copy_var ${uccloud}_RELATIVE service_relpath
    [ $? -ne 0 ] && report warn "$(cloud_error_display $cloud ${uccloud}_RELATIVE)" && continue
    setup_cloud_dir "$service_name" "$service_home" "$service_relpath"
done

# setup_cloud_dir "$DROPBOX" "$DROPBOX_HOME" "$DROPBOX_RELATIVE"
# setup_cloud_dir "$DRIVE" "$DRIVE_HOME" "$DRIVE_RELATIVE"



# function link_fhs () {
#     local d="$1" prefix primary cloud
# }
# link shared dirs
for d in "${FHS_LINKED[@]}" "$os" "$arch" "$site"; do
    prefix="var/$PRIMARY_CLOUD"
    for cloud in "${used_clouds[@]}"; do
        uccloud="$(uc "$cloud")"
        if isset _IN_${uccloud}_${d}; then
            prefix="var/$cloud"
            break
        fi
    done
    # for dir in "${IN_DRIVE[@]}"; do
    #     [[ "$d" = "$dir" ]] && prefix="var/$DRIVE/$GOOGLE_DRIVE_RELATIVE"
    # done
    link_to "$prefix/$d" "$USR_ABS"/"$d"
    # if [[ -e $d ]]; then
    #     report noop "$d already present" >&2
    # else
    #     report ok "linking ~/$USR/$d to ~/Dropbox/$DROPBOX_RELATIVE"
    #     ln -s ../Dropbox/$DROPBOX_RELATIVE/$d .
    # fi
done

makedir share/man
link_to share/man man

# Add anchor links to various roots

for d in . "${FHS_LINKED[@]}" "$arch" "$site" var "$LOCAL" "$LOCAL/bin" ; do
    d_norm="$(normalize "$d")"
    if [ -d "$d" -o -d "$d_norm" ]; then
        cd "$d"
        # relativize this
        link_to ../$ANCHOR $ANCHOR
        cd - >/dev/null
    fi
done

#icloud -> ../Library/Mobile Documents/com~apple~CloudDocs
popd >/dev/null

# link local cpan dir
link_to $USR/var/cpan ~/.cpan "$LOCAL_CPAN_BACKUP" 

# link ~/.*rc files 
for f in "${RC_LINKED[@]}"; do
    link_to $USR/etc/"$f" ~/".$f" "$LOCAL_CONFIG_BACKUP"
done

# platform-specific setup
run_if_present $HOME/usr/$os/sbin/setup-$os.bash

# site-specific setup
run_if_present $HOME/usr/site/sbin/setup-$site.bash

# site-specific, platform-specific setup
run_if_present $HOME/usr/site/sbin/setup-$site-$arch.bash
