#!/usr/bin/perl

my $root = $ARGV[0];
my @files = map {chomp} (`find '$root' -type f`);


for my $file (@files) {
    my $f;
    { local $/ = undef;
    open IN, $file;
    $f = <IN>;
    close IN; }
    s/((?:^|\n)((?:[^\t]{8})*)([^\t]{0,7})\t(\t+)/$1 . (' ' x (8-length($2))) . $3/eg;
}

