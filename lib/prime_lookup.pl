#!/usr/bin/env perl
use Data::Dumper;

#sub D(@) { print STDERR @_, "\n" }
sub D {}
my ($count, $min_digits, $max_digits, $twin) = ($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3]); shift; shift; shift; shift; #slice @ARGV, 0, 4;

#sub D(@) { print STDERR @_, "\n" }

D "count=$count min=$min_digits max=$max_digits twin=$twin\n";

my @f=(), @p=(), @selections=();

sub max($$) { $_[0] < $_[1] ? $_[1] : $_[0] }
sub min($$) { $_[0] > $_[1] ? $_[1] : $_[0] }

for my $n ($min_digits .. $max_digits) {
	D $n;
	push @f, ($n) x 2 ** (min $n-1, 3);
}

D Dumper(\@f);

sub grab(+$@){ my($ref, $i, @list) = @_; push $ref->[$i] ||= [], @list; $? }

sub T(&@) {
	my $sub = shift;
	my @args = shift;
	if (wantarray) {
		my @result = ( &$sub(@args) );
		D "(@args) => (@result)";
		return @result
	} else {
		my $result = scalar &$sub(@args);
		D "(@args) => $result";
		return $result
	}
}

sub see($) { m/\b\d{$_[0]}\b/ }

my $current_digits = $min_digits;
my $next_digits = $current_digits + 1;
my $in_run = 0;

while (<>) {
	chomp;
	die "too many lines" if ++$line > 10000;
	next if /[^\s\d]/;
	if ($in_run) {
		D " in run with $current_digits/$next_digits";
		my $seen = see "$next_digits,";
		D "  seen=$seen";
		if ($seen) {
			D "  saw a >$current_digits-digit prime";
			grab @p => length $_, $_ for split /\s+/;
			$next_digits = (++$current_digits) + 1;
			D "  now with $current_digits/$next_digits";
			last if $current_digits > $max_digits;
		} else {
			grab @p => $current_digits, split/\s+/
		}
	} elsif (see $current_digits) {
		++$in_run;
		grab @p => length $_, $_ for split /\s+/;
	}
}

sub r(+@){ $_[0][int rand @{$_[0]}]; }

while ($count--) {
	my $w = r @f;
	my $v = r$p[$w];
	# D "v =? $v\n";
	redo if $v{$v}++;
	# D Dumper({w=>$w, v=>$v});
	push @selections, $v
}

# D Dumper(\@p);

print "'", join(" ", map { $twin ? ($_, $_+2) : $_ } sort @selections), "'\n";

# prime_lookup.pl 1 3 3 1 twinprimesunder10M.txt

=head1 INPUT
# from https://primes.utm.edu/lists/small/100ktwins.txt
# retrieved 2020-02-11T11:58-08:00
# trimmed & truncated to <10,000,000
	The First 100,000 Twin Primes
	(First Prime of each Pair only)
3	5	11	17	29	41	59	71
101	107	137	149	179	191	197	227
239	269	281	311	347	419	431	461
521	569	599	617	641	659	809	821
827	857	881	1019	1031	1049	1061	1091
1151	1229	1277	1289	1301	1319	1427	1451
1481	1487	1607	1619	1667	1697	1721	1787
1871	1877	1931	1949	1997	2027	2081	2087
2111	2129	2141	2237	2267	2309	2339	2381
...
=cut

=head1 OUTPUT
count=1 min=3 max=3 twin=1
$VAR1 = [
		  3,
		  3,
		  3,
		  3
		];
v =? 
$VAR1 = {
		  'w' => 3,
		  'v' => undef
		};
$VAR1 = [
		  [
			'101',
			'107',
			'137',
			'149',
			'179',
			'191',
			'197',
			'227',
			'239',
			'269',
			'281',
			'311',
			'347',
			'419',
			'431',
			'461'
		  ],
		  undef,
		  undef,
		  [],
		  [
			'101',
			'107',
			'137',
			'149',
			'179',
			'191',
			'197',
			'227',
			'239',
			'269',
			'281',
			'311',
			'347',
			'419',
			'431',
			'461'
		  ]
		];
' 2'
=cut