#!/usr/bin/perl
use File::Spec;
use constant DEBUG_D => TRUE;
sub report(@);
my @args = @ARGV;
sub D(@) { print STDERR @_, "\n" }

sub p4_fstat($) {
    my $file = shift @_;
    my @r = `p4 fstat "$file"`;
    my $t = {};
    for my $l (grep {/\S/} @r) {
        if ( $l =~ /... ... (.+?)\n?$/) {
            my $bit = $1;
            if ( $bit =~ /(\S+?)(\d+)\s+(.*)$/ ) {
                $t->{$1}[$2] = $3;
            } elsif ( $bit =~ /(\S+)\s+(.*)$/ ) {
                $t->{$1} = $2;
            } else {
                die qq(couldn't understand fstat line: "$bit");
            }
        } elsif ( $l =~ /... (\S+) (.*?)\n?$/ ) {
            $t->{$1} = $2;
        } else {
            die qq(couldn't understand fstat line:\n$l");
        }
    }
    return $t;
}

sub p4_where($) {
    my $file = shift @_;
#    D "calling where" if DEBUG_D;
    my $r = `p4 where $file`; chomp $r;
#    D "done calling where" if DEBUG_D;
    my @parts = split m{ (?=/)}, $r;
    die qq(bad filename; couldn't split normally: "$file"->"$r") if @parts > 3;
    return @parts; # ($depot, $client, $local)
}
sub p4_where_local($) {
    my (undef, undef, $local) = p4_where($_[0]);
    return $local;
}
sub p4_where_depot($) {
    my ($depot, undef, undef) = p4_where($_[0]);
    return $depot;
}


sub want_to_see($) {
    my %f = %{$_[0]};
    return 1
    && ! ( $f{headAction} =~ /^delete$/ )
    && ! ( $f{headAction} =~ /^branch$/ )
}

my ($username, $path) = @args;
my $is_depot_path = $path =~ "^//";
$path = File::Spec->canonpath($path);
$path = p4_where_local "/$path" if $is_depot_path;
my $pattern = File::Spec->catdir($path, "...");
my $cmd = qq{p4 changes -s submitted -L -m 100 -u $username $pattern};
my @lines = `$cmd`;
my @clnums = ();
push @clnums, (split / /)[1] for grep {/^Change (\d+) on/} @lines;
#print join ", ", @clnums;
my @lines = ();
my %files = ();
for my $clnum (sort @clnums) {
    my $dpath = p4_where_depot $path;
    my $cmd = qq(p4 files $dpath/...\@$clnum,\@$clnum);
    #print STDERR "[ $cmd ]\n";
    my @results = `$cmd`;
    push @lines, @results;
    for my $event (@results) {
        $event =~ m{^([^#]+)#\d+ - };
        $files{$1}++;
    }
}
my @lines = sort @lines;
my @files = sort keys %files;

for my $entry (@files) {
    $entry = p4_fstat $entry;
}

print join "\n", map {$_->{depotFile}} grep {want_to_see $_} @files;


sub report(@) {
    my @ids = @_;
    print STDERR "\t$_: \"", eval("$_"), "\"\n" for @ids;
}





