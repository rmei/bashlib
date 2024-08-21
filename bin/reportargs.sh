#!/bin/bash
Args=("$@")
echo " \$0: \"$0\""
for (( i=0; ${#Args[@]} - $i; i=$i+1)) ; do echo " \$$((i+1)): \"${Args[i]}\"" ; done
