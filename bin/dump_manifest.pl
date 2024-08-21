#!/usr/bin/env perl
use M;

my $sorted = 0;
if ($ARGV[0] eq '-s') {
	shift @ARGV;
	$sorted = 1;
}
my $kv = qr{(?mx) ^ ([^:\s]+) : \s+ ( \S [^\x0a\x0d]* (?: [\x0d\x0a]+\  [^\x0d\x0a]* )* )? [\x0d\x0a]+ (?: (?=\S) | $ )};
slurp;

while ( m{$kv}g ) {
	my($k,$v)=($1, $2);
	#P "$k => $v";
	$v =~ s{\r\n }{}g;
	$h{$k} = $v;
}

sub maybesort(@) { ( $sorted ? sort(@_) : @_ ) }

my %conversion = (
	'Bundle-ClassPath' => ",",
	'Bundle-NativeCode' => sub { map { [ maybesort(split /; /) ] } maybesort(split /, /) },
	'Import-Package' => ", ",
	'Service-Component' => ",",
);

for my $key (sort keys %h) {
	if ($conversion{$key}) {
		my $sub = $conversion{$key};
		if (ref $sub eq 'CODE') {
			# D "$key has code";
		} else {
			my $reg=qr{$sub};
			# D "$key had a string: '$reg'";
			$sub = sub { maybesort(split /$reg/) };
		}
		local $_ = $h{$key};
		$h{$key} = [ &{ $sub } ];
	}
}

P DD \%h;