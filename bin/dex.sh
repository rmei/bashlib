#!/bin/bash
BE_VERBOSE=1
export LANG=en_US.utf8
V=""
[ "$BE_VERBOSE" -ne 0 ] && V=--verbose
echo "[ began job at "`date`" ]"
cd /home/ec2-user/Dropbox
tmpdir=/tmp/`basename "$0"`/"$$"
mkdir $V -p "$tmpdir"
F=(m/*.xls)
[ -f "$F" ] && for f in "${F[@]}"; do
    fdir=`dirname "$f"`
    fname=`basename "$f"`
    fname="${fname%.xls}"
    echo "[ $fname ]"
    orig="$fdir/$fname".txt
    bkup="$fdir/$fname"-backup.txt
    [ -f "$orig" ] && cp $V -f "$orig" "$bkup"
    f_csv="$tmpdir/$fname".csv
    f_tsv="$tmpdir/$fname".tsv
    ../usr/bin/xls2csv -b EUC-JP -a UTF-8 -x "$f" -c "$f_csv"
    usr/bin/csv2tsv "$f_csv" > "$f_tsv"
    mv $V "$f_tsv" "$orig"
    rm $V -f "$f"
done
#rm $V -fr "$tmpdir"
echo "[ ended job at "`date`" ]"
