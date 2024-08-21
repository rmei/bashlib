#!/bin/bash

ARGS=("$@")

if [ "${ARGS[0]}" = refine_arch ]; then
    release="$(uname -r)"]
    release="${release%%\.*}"
    case $release in
        8) oslabel="tiger";;
        9) oslabel="leopard";;
        10) oslabel="snowleopard";;
        11) oslabel="lion";;
        12) oslabel="mountainlion";;
        13) oslabel="mavericks";;
        14) oslabel="yosemite";;
        15) oslabel="elcapitan";;
        16) oslabel="sierra";;
        17) oslabel="highsierra";;
        18) oslabel="mojave";;
        19) oslabel="catalina";;
        20) oslabel="bigsur";;
        21) oslabel="monterey";;
        22) oslabel="ventura";;
        23) oslabel="sonoma";;
        *) oslabel="$release";;
    esac
    # maybe detect CPU architecture as well ...
    echo "darwin/$oslabel"
    exit 0
fi

echo "Setting-up ~/usr/darwin/..."

here="$(dirname "$0")/.."




#cd
#for f in devrc ; do
#    link_to usr/arch/etc/"$f" ~/".$f" "$LOCAL_CONFIG_BACKUP"
#done


# create shared volume link for iCloud, if present
link_to "../../Library/Mobile Documents/com~apple~CloudDocs" ~/usr/var/iCloud

declare ARCH


## Don't do this anymore: use ⌘+[shift]+.


#------------------------------------snip------------------------------------#

declare INIT_LIST="$here"/etc/homebrew-base
declare -r HOMEBREW_ROOT=/opt/homebrew
declare -r HOMEBREW_ROOT_DIR_GROUP=admin

##############################
##  Below here is Homebrew  ##
##############################

# optionally skip Homebrew
if [[ "${ARGS[0]}" =~ --?no-?brew ]]; then
    report info "skipping Homebrew"
    exit 0
fi

:<<EOF
drwxrwxr-x   54 rachel  admin   1728 Oct  3 11:14 Cellar
drwxrwxr-x    3 rachel  admin     96 Jun 19  2018 Frameworks
drwxrwxr-x   19 rachel  admin    608 Oct  3 11:13 Homebrew
drwxrwxr-x  688 rachel  admin  22016 Oct  3 11:14 bin
drwxrwxr-x   11 rachel  admin    352 Oct  2 17:26 etc
drwxrwxr-x   88 rachel  admin   2816 Oct  3 11:14 include
drwxr-xr-x    3 root    wheel     96 Apr 16  2018 jamf
drwxrwxr-x  205 rachel  admin   6560 Oct  3 11:14 lib
drwxr-xr-x    5 rachel  admin    160 Jan 10  2018 libexec
drwxrwxr-x   72 rachel  admin   2304 Oct  3 11:14 opt
dr-xr-x---   12 root    ossec    384 Jan 10  2018 ossec
drwxr-xr-x    3 root    wheel     96 Jan 10  2018 remotedesktop
drwxrwxr-x   30 rachel  admin    960 Oct  3 11:14 share
drwxrwxr-x    6 rachel  admin    192 Oct  3 11:14 var
EOF

brew_dirs=(Cellar Frameworks Homebrew bin etc include lib libexec opt sbin share var)
if [[ ! -d "$HOMEBREW_ROOT" ]]; then
    report ok "creating $HOMEBREW_ROOT"
    sudo mkdir "$HOMEBREW_ROOT"
fi
pushd "$HOMEBREW_ROOT" >/dev/null
for d in "${brew_dirs[@]}"; do
    if [[ ! -d "$d" ]]; then
        report ok "creating $PWD/$d"
        sudo mkdir "$d"
        sudo chown $USER:$HOMEBREW_ROOT_DIR_GROUP "$d"
        sudo chmod 0775 "$d"
    fi
    fstat=($(ls -l -d "$d"))
    expected_fmode="drwxrwxr-x"
    if [[ "${fstat[0]}" != "$expected_fmode" || "${fstat[2]}" != "$USER" || "${fstat[3]}" != "$HOMEBREW_ROOT_DIR_GROUP" ]]; then
        report ok "fixing permissions on $PWD/$d: expected=$expected_fmode/$USER/$HOMEBREW_ROOT_DIR_GROUP actual=${fstat[0]}/${fstat[2]}/${fstat[3]}"
        sudo chown $USER:$HOMEBREW_ROOT_DIR_GROUP "$d"
        sudo chmod 0775 "$d"
    fi
done
popd >/dev/null

# get Homebrew
if which brew >/dev/null; then
    # we already have homebrew
    report noop "Homebrew is already installed"
else
    report ok "installing Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# get Homebrew packages to install, forcibly including "bash"
declare -a packages_to_install=($(grep -v '^\s*#\|^\s*$' "$INIT_LIST"))
if grep -q '^bash$' "$INIT_LIST" ; then
    true # bash is already listed
else
    packages_to_install+=(bash)
fi

# install base packages
for pkg in "${packages_to_install[@]}" ; do
    # unset cask
    # if [[ "$pkg" =~ ^"cask("(.*)")"$ ]]; then
    #     cask=cask
    #     pkg="${BASH_REMATCH[1]}"
    # fi

    if brew list $pkg >/dev/null 2>&1; then
        report noop "Homebrew: $pkg already installed"
    else
        if [ "$pkg" == "fluor" ]; then
            report ok "Homebrew: pre-uninstalling $pkg to avoid collisions. This may update Homebrew, which can take a couple minutes."
            brew uninstall $pkg
        fi
        report ok "Homebrew: installing $pkg. This may update Homebrew, which can take a couple minutes."
        brew install $pkg
    fi
done

# look for an updated 

foundbash=$(brew unlink -n bash | grep /bin/bash\$)
# foundbash=""
# for path in $(which -a bash); do
#     if [[ "${path#/usr/local}" != "$path" ]]; then
#         foundbash="$path"
#         break
#     fi
# done
if [[ -z "$foundbash" ]]; then
    report warn "couldn't locate Homebrew-installed bash"
else
    if grep -q "$foundbash" /etc/shells ; then
        report noop "bash already registered in /etc/shells"
    else
        report ok "adding $foundbash to /etc/shells (you may be prompted for your password)"
        sudo sh -c "echo \"$foundbash\" >> /etc/shells"
    fi
    if [[ "$SHELL" != "$foundbash" ]]; then
        report ok "updating login shell for $USER to $foundbash (you may be prompted for your password)"
        chsh -s "$foundbash"
    else
        report noop "login shell for $USER is already $SHELL"
    fi
fi
