#!/usr/bin/env perl

use constant DEBUG => 1;
use Data::Dumper;
use Time::Piece;

sub D(_;@) { print STDERR @_, "\n" if DEBUG }
sub L(@) { "(" . join(', ', @_) . ")" }
sub abspath($) { $_[0] =~ s%^$ENV{HOME}/%~$ENV{USER}/%gr };
sub min($$) { return $_[0] <= $_[1] ? $_[0] : $_[1] }
sub max($$) { return $_[0] >= $_[1] ? $_[0] : $_[1] }

our $Now = Time::Piece->new();
our $COMMANDNAME = `basename "$0"`;

sub process_hosts_lines(+$@) {
    my ($data, $filename, @lines) = @_;
    $filename = abspath($filename);
    #D "processing ...";
    my %comments=();
    while ($_ = shift @lines) {
        chomp;
        #D;
        my %line=();
        do { splice(@lines, 0, $+{count}); $_=shift @lines; unshift @lines, $_ if $_; next }
            if m%## following (?<count>\d+) lines added by .*/$COMMANDNAME%;
        @line{qw(ipaddr host aliases comment)} = m{(?xms)
            ^
            (?: \s* # content line
                ( # IP address
                    [\da-fA-F:.]+
                )
                \s+
                ( # hostname
                    [^\s#]+
                )
                ( # aliases
                    (?: \s+ [^\s#]+ )+
                )?
            )?
            # comment
            \s* ( \# [^\n]* )?
            $
        }g;
        $line{aliases} =~ s%^\s+%%g if $line{aliases};
        $comments{$line{comment}}++;
        #D Dumper \%line;
        my $provenance = "# \@file:$filename \@date:".$Now->datetime();
        $data->{hosts}{$line{host}} = $data->{ipaddrs}{$line{ipaddr}} = { %line, file => $filename, provenance => $provenance }
            if $line{host} && $line{ipaddr};
    }
    D "processed into: ", Dumper [$data, \%comments];
}

my $TAB_WIDTH = 8;
my $GENERATED_LINE_PREFIX = " ";

=for comment
('  ', 2, 13, , -7, '23.20.182.173', '')
('  23.20.182.173', 15, 3, , -2, 'aws', '')
('  23.20.182.173aws', 18, 4, , 2, ' ec2', '')
#: following 1 lines added by /home/ubuntu/usr/sbin/hosts-update.pl 2020-02-20T06:05:53
  23.20.182.173aws ec2  #: @file ~/usr/etc/hosts # personal EC2 instance
Thu Feb 20 06:05:53 0 ubuntu@ip-172-30-0-241:~/usr/sbin$ 
=cut

sub append_field (\$$++) { # \line, key, data, tabs
    my ($l,$k,@x)=@_;
    my $p = length($$l);
    my $f = length($x[0]{$k});
    my $m = $x[1]{$k};
    my $w = $m - $f + $TAB_WIDTH - ($p + $m) % $TAB_WIDTH;
    D L "'$$l'", $p, $f, $m, $w, "'$x[0]{$k}'";
    $$l .= $x[0]{$k} . (" " x $w);
}

sub even(@) { my $bit = 0; grep {++$bit % 2} @_ }
sub odd(@) { my $bit = 1; grep {++$bit % 2} @_ }

sub text_table(+%) {
    my ($table, @cols) = @_;
    %cols = @cols;
    my $tmp = 0;
    @cols = even @cols;
    my %tabs = ();
    $tmp = 0;
    my @rows = ref $table eq "HASH" ? map {$_ => $table->{$_}} sort keys %$table : map {$tmp++ => $_} @$table;
    for my $row (odd @rows) {
        D Dumper \%tabs;
        for (keys %$row) {
            $tabs{$_} = max($tabs{$_}, length $row->{$_});
            D L $_, $tabs{$_}, $row->{$_}
        }
    }
    my @lines;
    for my $row (odd @rows) {
        my $line = $GENERATED_LINE_PREFIX;
        for my $col (@cols) {
            append_field $line, $col, $row, %tabs if $row->{$col};
        }
        $line =~ s% +$%%g;
        push @lines, $line;
    }
    return @lines;
}

sub text_table_in_place(+$%) {
    my ($table, $key, @cols) = @_;
    %cols = @cols;
    my $tmp = 0;
    @cols = even @cols;
    my %tabs = ();
    $tmp = 0;
    my @rows = ref $table eq "HASH" ? map {$_ => $table->{$_}} sort keys %$table : map {$tmp++ => $_} @$table;
    for my $row (odd @rows) {
        D Dumper \%tabs;
        for (keys %$row) {
            $tabs{$_} = max($tabs{$_}, length $row->{$_});
            D L $_, $tabs{$_}, $row->{$_}
        }
    }
    for my $row (odd @rows) {
        my $line = $GENERATED_LINE_PREFIX;
        for my $col (@cols) {
            append_field $line, $col, $row, %tabs if $row->{$col};
        }
        $line =~ s% +$%%g;
        $row->{$key} = $line;
    }
}

sub write_hosts(+$) {
    my ($data, $filename) = @_;
    D "writing: ", Dumper $data;
    my @rows = ();
    # my %tabs = ();
    # for my $host (sort keys %$data) {
    #     D $host, "  ", Dumper \%tabs;
    #     for (keys $data->{$host}) { my $max = max($tabs{$_}, length $data->{$host}{$_}); $tabs{$_} = $max; D L $_, $max, $tabs{$_}, $data->{$host}{$_}; }
    # }

    # for my $host (sort keys $data) {
    #     my $h = $data->{$host};
    #     my $line = $GENERATED_LINE_PREFIX;
    #     append_field $line, ipaddr => $h, %tabs;
    #     append_field $line, host => $h, %tabs;
    #     append_field $line, aliases => $h, %tabs if $h->{aliases};
    #     append_field $line, comment => $h, %tabs if $h->{comment};
    #     $h->{line} = $line;
    # }
    text_table_in_place($data, "line",
        ipaddr => undef,
        host => undef,
        aliases => undef,
        comment => undef,
    );
    my @rows = text_table($data,
        line => undef,
        provenance => undef,
    );
    if (@rows) {
        open(my $fh, ">>", $filename) or die "couldn't open $filename for writing";
        my $header = "## following ".@rows." lines added by ".abspath($0)." ".$Now->datetime;
        print $fh "\n", map {"$_\n"} $header, @rows;
        close $fh;
    }
    return scalar @rows;
}

sub load_hosts(+$) {
    my ($data, $filename) = @_;
    #D "loading into: ", Dumper $data;
    if (-e $filename) {
        open(my $fh, "<", $filename) or die "couldn't open $filename for reading";
        D "loading $filename";
        process_hosts_lines $data, $filename, (<$fh>);
        close $fh;
    } else {
        D "skipping $filename";
    }
}

if ($#ARGV < 2) {
    die "Usage: $0 /etc/hosts user/hosts-file1 [user/hosts-file2 ...]";
}


my %usr = ();
my $temp = "/tmp/hosts-update.$$";
D "temp: $temp";

my $target = shift;
for my $file (@ARGV) {
    load_hosts %usr, $file;
}

# D Dumper \%usr;

# request password, get sudo creds
system('sudo /bin/cat /dev/null &>/dev/null');

my @master = `sudo /bin/cat "$target"`;
my %master = ();

process_hosts_lines %master, $target, @master;

for (sort keys %{$master{hosts}}) {
    delete $usr{hosts}{$_};
}

my $rowcount = write_hosts $usr{hosts}, $temp;
D $rowcount;
system(qq(sudo bash -c 'cat "$temp" >> "$target"')) if $rowcount;

#D Dumper \%usr;


#D Dumper \@master;