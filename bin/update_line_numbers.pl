#!/usr/bin/perl
use constant DEBUG => 0;
use constant OOPS => 1;
# use Data::Dumper;

=for comment
=cut

sub D(@) { print STDERR @_, "\n" if DEBUG }

die "too many arguments (".scalar(@ARGV).")" if @ARGV > 2;
my $filetoload = $ARGV[0];
my $filename = $ARGV[1] || $filetoload;

my $filetext = do { local $/; <> };
my @lines = split /\n/, $filetext;


=head3 Pattern Fragments
=cut

# #...? $
my $comment = qr%(?xms: (?<= [(; \t] ) \# [^\n]* )%;

# provenance lines start with "true " or ": "
my $prov_prefix = qr%(?xms: (?: true | : ) )%;

# recursive matching (for balanced quotes) is probably necessary here ...
my $attribute_value = qr%(?xms:
    (?<attribute_value> [^\s@;] (?: [^@;\n]* [^\s@;] )? )
    [ \t]* (?=)
)%;

# (swallow whitespace up to the end of the attributes)
my $attribute_tail = qr%(?xms:
    [ \t]* (?:
          (?= ; )
        | (?= [ \t] \@ )
        | (?= $comment )
        | $
    )
)%;

my $preamble = qr%(?<preamble>(?xms)
    (?:
          (?<= \{ [ \t] )
        | (?<= ; )
        | (?<= ^ (?-x: {4}) )
    ) [ \t]* $prov_prefix (?: $ | (?= [; \t] ) )
)%;

my $to_preamble = qr%(?<to_preamble>(?xms)
    $preamble (?-x:[ \t]+" to\b)
)%;

my $file_preamble = qr%(?<file_preamble>(?xms)
    $preamble (?:
        \s+ \@ (?! file \b) \w+  # <whitespace> @other_identifier
        (?: \s $attribute_value )?         # ( <whitespace> ...whatever... )?
    )* \s+ \@file \b
)%;

# function foo ()?
my $fn1 = qr%(?xms: ^ function \s+ (?<fn>\S+) \s* (?: \(\) \s* )? )%;

# foo ()
my $fn2 = qr%(?xms: ^ \s* (?<fn>[\w~_-]+) \s* \(\) \s* )%;

my $body = qr%(?xms: \s+ \{ \s+ [^#\n]+? \s+ \} \s* )%;

D "$ARGV", scalar(@lines);

=head3 Pre-process lines; determine line #s for parts of each function
=cut
{
    my $fn = undef;
    for (@lines) { ++$line_number;
        my $index = $line_number - 1;
        # function foo ()? {? #...?
        if ( m%(?xms) $fn1 (?: \{ \s* )? $comment? $ % ) {
            $fn = $+{fn};
            $start{$fn} = $line_number;
            D "function $fn $line_number: '$_'";
        }
        # foo () {? #...?
        if ( m%(?xms) $fn2 (?: \{ \s* )? $comment? $ % ) {
            $fn = $+{fn};
            $start{$fn} = $line_number;
            D "$fn() $line_number: '$_'";
        }
        # function foo ()? { ... } #...?
        if ( m%(?xms) $fn1 $body \s* $comment? $ % ) {
            $fn = $+{fn};
            $start{$fn} = $line_number;
            $end{$fn} = $line_number;
            D "singlet1 $fn $line_number: '$_'";
        }
        # foo () { ... } #...?
        if ( m%(?xms) $fn2 $body $comment? $ % ) {
            $fn = $+{fn};
            $start{$fn} = $line_number;
            $end{$fn} = $line_number;
            D "singlet2 $fn $line_number: '$_'";
        }
        if ( /$to_preamble/ ) {
            $to{$fn} = $index;
            D "to $fn $line_number ($index): '$_'";
        }
        if ( /(?xms) $file_preamble (?: \s+ (?<old_file> $attribute_value ) )? / ) {
            $file{$fn} = $index;
            D "\@file $fn $line_number ($index): '$_'";
        }
        if ( /^\}/ ) {
            $end{$fn} = $line_number;
            D "end $fn $line_number: '$_'";
        }
    }
}

=head3 Update lines
=cut 
{
    sub oops(&\@$$) {
        my ($cmd, $lines, $label, $index) = @_;
        local $_ = $$lines[$index];
        my $result = &$cmd();
        $lines[$index] = $_;
        print STDERR "$label$index: oops: \"$$lines[$index]\"\n" if OOPS && ! $result;
        print STDERR "$label$index: + \"$$lines[$index]\"\n" if OOPS && DEBUG && $result;
        return $result;
    }

    my $file = "$filename";
    D "$file\n";
    $file =~ s%^(?!/)%$ENV{PWD}/%;
    $file =~ s%[^/]+/\.\./|/\.(?=/)%%g;
    D " $file\n";
    if ( ! -e $file ) {
        die "File '$file' does not exist!\n";
    }
    $file =~ s%$ENV{HOME}%~%g;
    #D Dumper({to => \%to, file => \%file});

    for my $fn (keys %to) {
        my $subst = "$file:$start{$fn}-$end{$fn}";
        my $ptn = qr%(?xms) $to_preamble \s+ (?<old_file_coords>\S[^\n:]*:[#\d-]+[ \t]*)%;
        oops { s%$ptn%$+{to_preamble} . " " . $subst . (" " x (length($+{old_file_coords}) - length($subst)))%e } @lines, "(to) ", $to{$fn};
    }
    for my $fn (keys %file) {
        my $subst = "$start{$fn} $end{$fn} $file";
        my $ptn = qr%(?xms) $file_preamble (?: [ \t]+ $attribute_value )? $attribute_tail %;
        oops { s%$ptn%$+{file_preamble} $subst% } @lines, "(file) ", $file{$fn};
    }
}
=head3 Output
=cut

print map {"$_\n"} @lines;

1