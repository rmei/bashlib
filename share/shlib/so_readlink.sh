FILE=$(perl -e "use Cwd qw(abs_path); print abs_path('$0')")

FILE="$(perl -MCwd -le 'print Cwd::abs_path(shift)' "$path")"
HERE="$(dirname "$(perl -MCwd -le 'print Cwd::abs_path(shift)' "$path")")"
# rreadlink:

#!/bin/sh

# SYNOPSIS
#   rreadlink <fileOrDirPath>
# DESCRIPTION
#   Resolves <fileOrDirPath> to its ultimate target, if it is a symlink, and
#   prints its canonical path. If it is not a symlink, its own canonical path
#   is printed.
#   A broken symlink causes an error that reports the non-existent target.
# LIMITATIONS
#   - Won't work with filenames with embedded newlines or filenames containing 
#     the string ' -> '.
# COMPATIBILITY
#   This is a fully POSIX-compliant implementation of what GNU readlink's
#    -e option does.
# EXAMPLE
#   In a shell script, use the following to get that script's true directory of origin:
#     trueScriptDir=$(dirname -- "$(rreadlink "$0")")
rreadlink() ( # Execute the function in a *subshell* to localize variables and the effect of `cd`.

  target=$1 fname= targetDir= CDPATH=

  # Try to make the execution environment as predictable as possible:
  # All commands below are invoked via `command`, so we must make sure that
  # `command` itself is not redefined as an alias or shell function.
  # (Note that command is too inconsistent across shells, so we don't use it.)
  # `command` is a *builtin* in bash, dash, ksh, zsh, and some platforms do not 
  # even have an external utility version of it (e.g, Ubuntu).
  # `command` bypasses aliases and shell functions and also finds builtins 
  # in bash, dash, and ksh. In zsh, option POSIX_BUILTINS must be turned on for
  # that to happen.
  { \unalias command; \unset -f command; } >/dev/null 2>&1
  [ -n "$ZSH_VERSION" ] && options[POSIX_BUILTINS]=on # make zsh find *builtins* with `command` too.

  while :; do # Resolve potential symlinks until the ultimate target is found.
      [ -L "$target" ] || [ -e "$target" ] || { command printf '%s\n' "ERROR: '$target' does not exist." >&2; return 1; }
      command cd "$(command dirname -- "$target")" # Change to target dir; necessary for correct resolution of target path.
      fname=$(command basename -- "$target") # Extract filename.
      [ "$fname" = '/' ] && fname='' # !! curiously, `basename /` returns '/'
      if [ -L "$fname" ]; then
        # Extract [next] target path, which may be defined
        # *relative* to the symlink's own directory.
        # Note: We parse `ls -l` output to find the symlink target
        #       which is the only POSIX-compliant, albeit somewhat fragile, way.
        target=$(command ls -l "$fname")
        target=${target#* -> }
        continue # Resolve [next] symlink target.
      fi
      break # Ultimate target reached.
  done
  targetDir=$(command pwd -P) # Get canonical dir. path
  # Output the ultimate target's canonical path.
  # Note that we manually resolve paths ending in /. and /.. to make sure we have a normalized path.
  if [ "$fname" = '.' ]; then
    command printf '%s\n' "${targetDir%/}"
  elif  [ "$fname" = '..' ]; then
    # Caveat: something like /var/.. will resolve to /private (assuming /var@ -> /private/var), i.e. the '..' is applied
    # AFTER canonicalization.
    command printf '%s\n' "$(command dirname -- "${targetDir}")"
  else
    command printf '%s\n' "${targetDir%/}/$fname"
  fi
)

rreadlink "$@"



