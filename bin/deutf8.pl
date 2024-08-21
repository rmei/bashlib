#!/usr/bin/perl
use bytes;
sub d($@) {
    my $pattern = shift;
    print STDERR sprintf($pattern . "\n", @_);
}
sub unibyte($) {
    my $c = shift @{$_[0]};
    die unless $c >> 6 == 2;
    return $c & 0x3f;
}
sub utf8char(\@) {
    my $a = shift;
    my $c = shift @$a;
    die unless $c < 0x100;
    die unless $c > 0;
    d "%02.2x", $c;
    return $c if $c < 0x80;
    d "%x", $c ^ 0x40;
    die unless ($c ^ 0x40);
    $c &= 0x3f;
    for my $d (1..3) {
        unless ($c & (1 << 6-$d)) {

            d "char has %d bytes", $d+1;
            die unless @$a >= $d;
            $c &= 0x3f >> $d;
            $c = $c << 6 | unibyte($a) while $d--; return $c

        }
    }
}

sub c {
    my @t=();
    my @a=@_;
    push @t, sprintf("%04x", utf8char @a) while @a;
    return @t;
}

my @foo;
{ local $/=undef;
@foo = grep {$_ != 10} split /\s+/, `od -t u1 ~/halflong | cut -sd' ' -f2-`;
}
d join ", " , @foo;
print join(" ",c(@foo))."\n";
#print join(" ", c(qw(203 145  10 101 204 158  10 201 170  10)))."\n";
