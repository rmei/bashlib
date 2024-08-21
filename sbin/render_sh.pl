#!/usr/bin/env perl

my $source = shift;
my $target = shift;

# find the path our inclusions are relative to
my $base = qx(cd `dirname "$source"`; pwd); chomp $base;

open $fh, "<$source" or die "couldn't open '$source' for read";
my $text = do {local $/; <$fh>};
close $fh;

print "Base: $base\n";

my $preceding_separator = qr{
    (?: ^ # preceding statement separator
      | (?<= [(;] )
      | (?<= \{ [ \t] )
    )
}xm;

my $trailing_separator = qr{
    (?: $ | (?= [;)] ) )
}xm;

my $token = qr{
    (?:   (?: # unquoted non-whitespace & escaped whitespace
            [^\s;] | (?<!\\) (?:\\{2})* \\ [\s;] )
        | (?: " # double-quoted text
            (?: [^"] | (?<!\\) (?:\\{2})* \\ " )+
            " )
        | (?: ' [^']+ ' ) # single-quoted text
        | (?: \$' [^']+ ' ) # dollar-quoted escape text (unlikely!)
    )+ (?= [\s;] )
}x;

sub cat($) {
    my ($file) = @_;
    $file = "$base/$file";
    open $fh, "<$file" or die "couldn't open '$file' for read";
    my $text = do {local $/; <$fh>};
    close $fh;
    return $text;
}

sub report() {
    if ( $+{action} eq "INCLUDE" ) {
    } elsif ( $+{action} eq "INCLUDE_AS_ARRAY" ) {
        $message = qq(array name: $+{array_name});
    } elsif ( $+{action} eq "INCLUDE_PERL" ) {
        $message = qq(args:$+{arguments}) if $+{arguments};
    }
    print "$+{action}: $+{file}\n";
    print "    $message\n" if $message;
}

=for examples
HERE_="$(cd "$(dirname "$BASH_SOURCE")"; pwd)"
function INCLUDE () { source "$HERE_/$1"; }
function INCLUDE_AS_ARRAY () { source /dev/stdin <<< "$(echo "$1=("; cat "$HERE_/$2"; echo; echo ")")"; }
function INCLUDE_PERL () { declare src="$1"; shift; perl - "$@" <"$HERE_/$src"; }

INCLUDE utilities.sh

function foo () {
    declare -a top250
    INCLUDE_AS_ARRAY top250 /etc/misc/top_250_favorite_quotes.txt

    INCLUDE_PERL setup_wsu.pl "$wsu_backup" "${modules[@]}" >"$wsu"
}
=cut

$text =~ s{(?xm) $preceding_separator
    (?<indent> [ \t]* ) (?<action>INCLUDE)
    [ \t]+ (?<file>$token)
    (?<tail>[ \t]* ) $trailing_separator
}{
    report;
    $+{indent} . cat($+{file}) . $+{tail}
}ge;

$text =~ s{(?xm) $preceding_separator
    (?<indent> [ \t]* ) (?<action>INCLUDE_AS_ARRAY)
    [ \t]+ (?<array_name>$token)
    [ \t]+ (?<file>$token)
    (?<tail>[ \t]* ) $trailing_separator
}{
    report;
    $+{indent}
        . $+{array_name}
        . "=(\n"
        . cat($+{file})
        . "\n)"
        . $+{tail}
}ge;

$text =~ s{(?xm) $preceding_separator
    (?<indent> [ \t]* ) (?<action>INCLUDE_PERL)
    [ \t]+ (?<file>$token)
    (?<arguments> (?: [ \t]+ $token )* )
    (?<tail>[ \t]* ) $trailing_separator
}{
    report;
    qq($+{indent}perl -$+{arguments} <<"END_PERL"\n)
        . cat($+{file})
        . "\nEND_PERL"
        . ( substr($+{tail},0,1) eq "\n" ? $+{tail} : "\n$+{tail}" )
}ge;

open $fh, ">$target" or die "couldn't open '$target' for write";
print $fh $text;
close $fh;

