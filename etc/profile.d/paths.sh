#!/bin/sh

pathmunge /usr/local/sbin
pathmunge /usr/local/bin
EYRIE_HOME=$HOME/usr
MANAGED_HOME=/opt/homebrew
for BIN in sbin bin ; do
  for scope in $MANAGED_HOME $EYRIE_HOME{,/{arch,site{,/arch},local}} ; do
    pathmunge "$scope/$BIN"
  done
done
unset BIN scope
export PATH

:<<'Precedence_MD'

# General Hierarchies of Precedence

( ~/eyrie == Eyrie root )

    ~
    ~/eyrie/local
    ~/eyrie/site/arch
    ~/eyrie/site
    ~/eyrie/arch
    ~/eyrie
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

    ~/.* (usually symlinked to ~/eyrie{...}/etc/*)
    ~/eyrie/local/etc
    ~/eyrie/site/arch/etc
    ~/eyrie/site/etc
    ~/eyrie/arch/etc
    ~/eyrie/etc

PATH

    $EYRIE/local/...
  ? $EYRIE/site/arch/...
  ? $EYRIE/site/...
  ? $EYRIE/arch/...
    $EYRIE/...

    $PKG_OPT/...
    /usr/local/...
  ? /usr/site/arch/...
  ? /usr/site/...
  ? /usr/arch/...
    /usr/...
    /...

    # ~/sbin
    # ~/bin
    ~/eyrie/local/sbin
    ~/eyrie/local/bin
    ~/eyrie/site/arch/sbin
    ~/eyrie/site/arch/bin
    ~/eyrie/site/sbin
    ~/eyrie/site/bin
    ~/eyrie/arch/sbin
    ~/eyrie/arch/bin
    ~/eyrie/sbin
    ~/eyrie/bin
    /usr/local/sbin
    /usr/local/bin
    /usr/sbin
    /usr/bin
    /sbin
    /bin

Precedence_MD