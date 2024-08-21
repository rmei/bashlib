package M;

use base qw(Exporter);

$M::VERSION = '0.4-SNAPSHOT';

=for html
<div class="row main-content pb-5 pt-5 col-sm-10 offset-sm-1 col-xl-8 offset-xl-2">
<article class="col-sm-12 content">
=cut

=head1 NAME

M - utility methods and language extensions

=head1 SYNOPSIS

    use M;

    I<... [ insert friendly example usage here ] ...>

=head1 DESCRIPTION

I<... [ this space regrettably left blank ] ...>

=cut

@M::EXPORT = (
    ## basic void primitives, control flow, and shortcuts
    qw( D P Pf println

        L DD

        chompr

        ifnot
        ifundef
        ifblank
        ifempty

        min max
        round

        is_interval

        check_arg_ref
        caller_hash
    ),

    ## string utilities
    qw( similar
        edit_distance
        deSGI
        strptime_8601
    ),

    ## novel syntax
    qw( X couple ),

    ## basic file actions
    qw( slurp
        to_file

        ls
        sibling_file

        find
    ),

    ## assembling data structures
    qw( sublist
        subhash
        hash_key_diff

        put
        pushto

        unionto

        ordered_hash

        zip
        zip_fuzzy
        zip_exact

        distinct
        complement

        binsearch
    ),

    ### Reporting & working with various file formats

    ## working with complex records
    qw( clone_tree

        load_index
        search_index

        save_ref
        restore_ref
    ),

    ## working with CSV files
    qw( csv_file_to_rows

        csvquote
        csvline

        records_to_rows
        records_to_rows_x

        rows_to_records

        rotate_rows_to_columns
    ),

    ## interaction/interdependency with shell scripts
    # qw( load_bash_names ),

    ## JSON utilities
    # (temporarily disabled pending some refactoring)
    qw(

    ),
    ##
    ## re-exports
    ##
    # qw( 
    #     decode_json
    #     encode_json
    # ),

);

@M::EXPORT_OK = (
    qw( e )
);

%M::EXPORT_TAGS = (
    ## XML utilities
    xml => [qw(
        e
    )],
);



##
## Perl builtin libs
##  requires 5.8, soft-requires 5.14 (for JSON::PP)
##

use v5.8.0;
use File::Find ();  # 5.6?
use File::Spec;     # 5.1?
use Data::Dumper;   # 5.0?
use Time::Local;
#use JSON::PP;       # 5.14
use Memoize;        # 5.8

#use M::Eng;

$Data::Dumper::Sortkeys = 1;

=head1 VARIABLES

I<... [ this space regrettably left blank ] ...>

=over

=cut

BEGIN {
    our $DEBUG = 1;
    our $RED = "\e[31;1m";
    our $OFF = "\e[0m";
}

use constant DEBUG => $M::DEBUG;


=back

=head1 CONSTANTS

=over

=cut

our @Greek = (
    { name => 'alpha',      upper => 'Α', lower => 'α', latin => 'a' },
    { name => 'beta',       upper => 'Β', lower => 'β', latin => 'b' },
    { name => 'gamma',      upper => 'Γ', lower => 'γ', latin => 'g' },
    { name => 'delta',      upper => 'Δ', lower => 'δ', latin => 'd' },
    { name => 'epsilon',    upper => 'Ε', lower => 'ε', latin => 'e' },
    { name => 'zeta',       upper => 'Ζ', lower => 'ζ', latin => 'z' },
    { name => 'eta',        upper => 'Η', lower => 'η', latin => 'h' },
    { name => 'theta',      upper => 'Θ', lower => 'θ', latin => 'th' },
    { name => 'iota',       upper => 'Ι', lower => 'ι', latin => 'i' },
    { name => 'kappa',      upper => 'Κ', lower => 'κ', latin => 'k' },
    { name => 'lambda',     upper => 'Λ', lower => 'λ', latin => 'l' },
    { name => 'mu',         upper => 'Μ', lower => 'μ', latin => 'm' },
    { name => 'nu',         upper => 'Ν', lower => 'ν', latin => 'n' },
    { name => 'xi',         upper => 'Ξ', lower => 'ξ', latin => 'xs' },
    { name => 'omicron',    upper => 'Ο', lower => 'ο', latin => 'o' },
    { name => 'pi',         upper => 'Π', lower => 'π', latin => 'p' },
    { name => 'rho',        upper => 'Ρ', lower => 'ρ', latin => 'r' },
    { name => 'sigma',      upper => 'Σ', lower => 'σ', latin => 's' },
    { name => 'tau',        upper => 'Τ', lower => 'τ', latin => 't' },
    { name => 'upsilon',    upper => 'Υ', lower => 'υ', latin => 'u' },
    { name => 'phi',        upper => 'Φ', lower => 'φ', latin => 'ph' },
    { name => 'chi',        upper => 'Χ', lower => 'χ', latin => 'x' },
    { name => 'psi',        upper => 'Ψ', lower => 'ψ', latin => 'ps' },
    { name => 'omega',      upper => 'Ω', lower => 'ω', latin => 'w' },
);

our %Greek = map { $_->{name} => $_ } @Greek;

=head1 FUNCTIONS

Subroutine names that are exported by default.

=head2 Void IO Primitives

These functions return nothing of use; they are pure side-effect statements,
and are intentionally kept simple.

=over

=cut

=item * S< D I<[ arg1, ... , argN ]> >
S< debug output, with trailing newline >
    X<D>

Print the concatenation of the argument list to STDERR, followed by a newline,
I<IFF> debugging is enabled. If an empty argument list is given, C<$_> will be
printed.

=cut

sub D(_@) { print STDERR @_, "\n" if DEBUG }

=item * S< P [I< arg1 ... , argN >] >

=item * S< println [I< arg1, ..., argN >] >
S< shortcut for C<print>, with trailing newline >
    X<P>

Print the concatenation of the argument list to STDOUT, followed by a newline.
If an empty argument list is given, C<$_> will be printed, instead.

=cut

sub P(_@) { print STDOUT @_, "\n" }

=back

=head2 String Formatting / Trimming

=over

=cut

=item * S< L I<$arg1> [I<arg2>, I<...>] >
S< format as list >
    X<L>

Returns a string consisting of the argument list, delimited with "C<, >", and
enclosed by "C<[ >" and "C< ]>".

=cut

sub L(@) { "[ " . join(", ", map { s/"/\\"/g; /["",]/ ? qq("$_") : $_ } @_) . " ]" }

=item * S< F [ I<$format> [, I<$val1>, I<$val2>, ...] ] >
S< shortcut for C<sprintf> >
    X<F>

Return  C<format>, with C<val1>, C<var2>, etc., interpolated as by L<sprintf>.
With no arguments, return the empty string.

=cut

sub F(@) { @_>0 ? sprintf @_ : "" }

=item * S< DD [ I<arg1> [, I<arg2>, I<arg3>, ...] ] >
S< shortcut for L<Data::Dumper> >

=cut

sub DD(_@) { Dumper( @_ > 1 ? \@_ : ref $_[0] ? $_[0] : \$_[0] ) }

=item * S< chompr [ I<$string> ] > S< stateless C<chomp> >

=cut 

sub chompr(;$) { return chompr($_) unless @_; chomp $_[0]; $_[0] }

=back

=head2 Alternate Values

Simple routines for supplying a value, along with an alternate value should
the original fail to satisfy a basic predicate (generally a variant or subset
of standard boolean conversion).

=over

=cut

=item * S< ifnot ( $value, $default ) >
S< use alternate unless C<$value> is true >

=cut

sub ifnot($$) { $_[0] ? $_[0] : $_[1] }

=item * S< ifundef ( $value, $default ) >
S< use alternate unless C<$value> is defined >

=cut

sub ifundef($$) { defined $_[0] ? $_[0] : $_[1] }

=item * S< ifblank ( $value, $default ) >
S< use alternate unless $value has non-whitespace >

=cut

sub ifblank($$) { length(s/\s+//gr) ? $_[0] : $_[1] }

=item * S< ifempty ( $value, $default ) >
S< use alternate unless C<$value> has characters >

=cut

sub ifempty($$) { length $_[0] ? $_[0] : $_[1] }

=back

=head2 Common Tests

=over

=cut

=item * S< is_interval ( I<$i>, I<$factor> ) > S< true IFF C<$i> is a nonzero multiple of C<$factor> >

=cut

sub is_interval($$) { $_[0] and ! ( $_[0] % $_[1] ) }

=back

=head2 List & Hash Operations

=over

=cut

=item * S< sublist I<@array>, I<$offset> [, I<$length>] >

=cut

sub sublist(+$;$) {
    my ($ref, $offset, $length) = @_;
    die "not an ARRAY ref: " . ref($ref) unless ref $ref eq 'ARRAY';
    $length = @$ref - $offset unless defined $length;
    my $last = $offset + $length - 1;
    return () if $last < $offset;
    return @$ref[$offset .. $last];
}

=item * S< subhash I<%hash> [, I<@keys>] >
S< "structural" hash slice >

Given a hash and a (possibly empty) list of keys,
returns a new hash consisting of each C<$keyE<0x02192>$value> pair present
in C<%hash> where C<$key> E<isin> C<@keys>. If no keys are specified, returns an
empty hash.

=cut

sub subhash(+@) {
    my ($source, @keys) = @_;
    return map { $_ => $source->{$_} } grep { exists $source->{$_} } @keys;
}

# E<0x027f6> ... xrarr, long right arrow

=item * S< hash_key_diff ( I<\%left>, I<%right> ) >
S< set-difference, over hash keys >

Given C<%left> and C<%right>, returns a new hash consisting of
each C<$keyE<rarr>$value> pair from C<%left> where C<$key> E<notin>
C<keys %right>.

=cut

sub hash_key_diff(+%) {
    my ($left, %right) = @_;
    my %left = %$left;
    delete $left{$_} for keys %right;
    return %left;
}

#sub do_if(&)
# use M::Bash;
# sub load_bash_names($) {
#     M::Bash::load_bash_names($_[0]);
# }

=back

=head2 Common I/O

=over

=cut

=item * S< slurp [ I<$filename> ] >
S< grab file content to a variable >

Open C<$filename> for reading, read it all into a scalar, close the file,
and return the file content. If C<$filename> is not specified, opens the
file named by the value of C<$_>. If called in a void context, assigns the
content to C<$_>. If called in list context, splits the content on C<$/>
and returns the resulting list. Otherwise returns the content.

=cut

sub slurp(_) {
    my ($filename) = @_;
    my $used_argv = 0;
    if ( ! defined $filename) {
        my @context = caller 1;
        ++$used_argv if @context == 0;
        $filename = $::ARGV[0] if $used_argv;
    }
    local $M::fh;
    open $M::fh, "<$filename" or die "couldn't open '$filename' for read: $!";
    my $s = do {local $/; <$M::fh>};
    close $M::fh;
    shift @::ARGV if $used_argv;
    if (defined wantarray) {
        return split m%$/%, $s if wantarray;
        return $s unless wantarray;
    } else {
        $_ = $s;
    }
}

=item * S< to_file I<$filename>, I<$scalar> >
S< dump string to file >

Open C<$filename> for writing, C<print> the value of C<$scalar> to file,
and close the file.

=cut

sub to_file($$) {
    my ($file, $string) = @_;
    local $M::fh;
    open $M::fh, ">$file" or die "couldn't open '$file' for write: $!";
    print $M::fh $string;
    close $M::fh;
}

sub ls($) {
    my ($dirname) = @_;
    local $M::dh;
    opendir $M::dh, $dirname or die "couldn't opendir '$dirname': $!";
    my @entries = readdir $M::dh;
    closedir $M::dh;
    return grep { ! /^\.{1,2}$/ } @entries;
}

sub sibling_file($%) {
    my ($base_file, %opts) = @_;
    my ($volume, $path, $base_name) = File::Spec->splitpath($base_file);
    my $sibling;
    if ( $base_name =~ /^(?<name> .+? )(?<ext> \. \w+ )?$/x ) {
        $sibling = $+{name};
        $sibling = $opts{prefix} . $sibling if defined $opts{prefix};
        $sibling = $sibling . $opts{suffix} if defined $opts{suffix};
        $sibling .= defined($opts{ext}) ? length($opts{ext}) ? ".$opts{ext}" : "" : $+{ext};
    } else {
        die "can't make sibling for filename '$base_name'";
    }
    return File::Spec->catpath($volume, $path, $sibling);
}

my @file_find_opts = qw(
    bydepth
    preprocess
    postprocess
    follow
    follow_fast
    follow_skip
    dangling_symlinks
    no_chdir
    untaint
    untaint_pattern
    untaint_skip
);

sub find(&@) {
    my ($predicate, @paths) = @_;
    my $opts = ref $paths[0] eq 'HASH' ? shift(@paths) : {};
    my %find_opts = subhash $opts, @file_find_opts;
    $opts = { hash_key_diff $opts, %find_opts };
    # here is where we can decorate %find_opts based on special flags in $opts
    my $existing_preprocess = $find_opts{preprocess};
    $find_opts{preprocess} = sub {
        @_ = &$existing_preprocess(@_) if $existing_preprocess;
        return sort @_;
    };
    #   ... (any other decorations) ...
    my @results = ();
    File::Find::find {
        wanted => sub {
                my ($fullpath, $dirname, $default) = ($File::Find::name, $File::Find::dir, $_);
                my $basename = File::Spec->abs2rel($fullpath, $dirname);
                local ($_, $::find_basename, $::find_dirname, $::find_fullpath) = ($default, $basename, $dirname, $fullpath);
                my $retval = undef;
                eval { $retval = &$predicate() };
                die "issue executing predicate on $fullpath: $! $@" if $!;
                if ($retval) {
                    push @results, File::Spec->catpath(undef, $dirname, $basename);
                }
            },
        %find_opts,
    }, @paths;
    # assemble a return value
    return @results;
}
# output date/time in ISO 8601 format.  FMT='date' for date only (the default), 'hours', 'minutes', 'seconds', or 'ns' for date and time to the indicated precision.  Example: 2006-08-14T02:34:56-06:00

sub strptime_8601($) {
    #2006-08-14T02:34:56-06:00
    my ($year, $dsep, $month, $mday, $hour, $tsep, $minute, $second, $tz_hour, $tz_minute) =
        ($_[0] =~ m{
            ^ (\d{4}) ([-/]) (\d{2}) \2 (\d{2})
            T (\d{2}) ([:]) (\d{2}) \6 (\d{2})
            (?: Z? (-?\d{1,2}) (?: \6 (\d{2}) )? )? $
        }x);
    # D $_[0], ": $year, $dsep, $month, $dsep, $mday, $hour, $tsep, $minute, $tsep, $second, $tz_hour, $tz_minute";
    return timelocal( $second, $minute, $hour, $mday, $month-1, $year-1900 );
}

sub _deSGI(\$) {
    my $r = shift;
    $$r =~ s%\x1b\[[0-9;]*m%%g;
}
sub deSGI(;\$) {
    if (@_) {
        my $r = shift;
        _deSGI $$r;
    } else {
        _deSGI $_;
    }
}

sub round($$) {
    my ($place, $value) = @_;
    my $d = $value; my $scale = 10**(-1 * $place);
    $d *= $scale;
    $d = ($d * 10 % 10 >= 5 ? 1 : 0) + int $d;
    $d /= $scale;
    return $d;
}

sub ult(&@) {
    my $rel = shift;
    return undef if @_ < 1;
    return $_[0] if @_ == 1;
    my $ult = $_[0];
    for (@_) { $ult = $_ unless &$rel($ult) }
    return $ult;
}

sub min(@) { ult { $_[0] < $_ } @_ }

sub max(@) { ult { $_[0] > $_ } @_ }

=for original
sub csv_to_rows(@) {
    my @lines = @_;
    my @rows = ();
    for (@lines) {
        chomp;
        my @fields = split /^"|","|"$/;
        shift @fields; # swallow junk element
        s%""%"%g for @fields;
        push @rows, [ @fields ] if @fields;
    }
    return @rows;
}
=cut

sub zip_exact(+@) {
    my ($l, @r) = @_;
    my $r = \@r;
    die "first argument to zip must be array or eval to an ARRAY ref" unless ref $l eq 'ARRAY';
    die "different lengths: l/r -> ".@$l."/".@$r unless @$l == @$r;
    map { $l->[$_], $r->[$_] } ( 0 .. $#$l );
}

sub zip_fuzzy(+@) {
    my ($l, @r) = @_;
    die "first argument to zip must be array or eval to an ARRAY ref" unless ref $l eq 'ARRAY';
    if (@$l > @r) {
        push @r, ( ( undef ) x (@$l - @r) );
    } elsif (@r > @$l) {
        $l = [ @$l , ( ( undef ) x (@r - @$l) ) ];
    }
    zip_exact $l, @r;
}

sub zip(+@) {
    # should be governed by `use strict`, if possible. exact if strict, fuzzy if not.
    my $l = shift; zip_exact($l, @_);
}

=item * S< binsearch I<&code PREDICATE>, I<$hashref CONTEXT>, I<@array DATA_TO_SEARCH> >
S< perform a serial L->R binary search applying PREDICATE over DATA_TO_SEARCH >

Values matching PREDICATE will be returned, along with their positions in the
DATA_TO_SEARCH sequence, and the output of PREDICATE for each matched value.

CONTEXT will be passed to each invocation of PREDICATE, in turn. PREDICATE
should be a subroutine accepting CONTEXT (a hashref), and a sequence of values
to analyze.

Currently also prints positions and values matching PREDICATE to stderr. Probably
 shouldn't do that.
=cut

sub binsearch(&$@) {
    my ($predicate, $context, @list) = @_;
    my $data = {
        # positions => [],
        matches => [],
        context => $context,
    };
    binsearch_internal($predicate, $data, 0, 1, @list);
    return {
        # positions => $data->{positions},
        matches => $data->{matches},
    };
}

sub binsearch_internal(&$$$@) {
    my ($predicate, $data, $iter, $pos, @list) = @_;
    my $result = &$predicate($data->{context}, @list);
    if ($result) {
        my $len = @list;
        if ($len > 1) {
            my $odd = $len % 2;
            --$len if $odd;
            my $left_size = $len / 2;
            my $right_size = $len / 2;
            ++$left_size if $odd;
            binsearch_internal($predicate, $data, $iter+1, $pos, sublist(@list, 0, $left_size));
            binsearch_internal($predicate, $data, $iter+1, $pos+$left_size, sublist(@list, $left_size, $right_size));
        } else {
            push @{$data->{matches}}, [ $list[0], $result ];
            print STDERR "$pos\t($iter)\t$list[0]\t1\t$result\n";
        }
    } else {
        print STDERR "$pos\t($iter)\t\[no match\]\t".scalar(@list)."\n";
    }
}

sub distinct(@) { my %tmp = ( map {$_ => 1} @_ ); sort keys %tmp; }

sub put(+@) {
    my ($h, $key, $value) = @_;
    die "first arg to put must be a HASH ref" unless ref $h eq 'HASH';
    $h->{$key} = $value;
}

=item * S< pushto I<SCALAR LVALUE> [ I<SCALAR> ... ] >
=item * S< pushto I<$hash{key}> [ I<SCALAR> ... ] >
=item * S< pushto I<$array[index]> [ I<SCALAR> ... ] >
S< treat LVALUE as an I<N>-tuple and add zero or more elements >

(Conceptually, I<N> may be zero). If the LVALUE is S<undef>, replace it with
a new empty array reference. If the LVALUE contains a I<SCALAR>, replace it
with a new arrayref containing one element: the previous value. Once we've
ensured that the LVALUE is now an arrayref, push the remaining parameters
onto it.
=cut

sub pushto(\$@) {
    my ($r, @list) = @_;
    die "first arg to pushto must be a ref" unless ref $r;
    if (ref $r eq 'SCALAR') {
        if (defined $$r) {
            $$r = [ $$r ];
        } else {
            $$r = [];
        }
    } elsif (ref $r eq 'REF' and ref $$r eq 'ARRAY') {
        # no-op
    } else {
        die "first arg to pushto must point to a SCALAR or an ARRAY ref";
    }
    push @{$$r}, @list;
}

=item * S< unionto I<SCALAR LVALUE> [ I<SCALAR> ... ] >
=item * S< unionto I<$hash{key}> [ I<SCALAR> ... ] >
=item * S< unionto I<$array[index]> [ I<SCALAR> ... ] >
S< treat LVALUE as an I<N>-cardinality set and offer zero or more new members >

(Conceptually, I<N> may be zero)
If the LVALUE is S<undef>, replace it with a new empty hash reference.
If the LVALUE contains a I<SCALAR>, replace it with a new hashref mapping
 that value to 1.
Once we've ensured that the LVALUE is now a hashref, treat the remaining parameters
 as keys and increment their respective values.
=cut

sub unionto(\$@) {
    my ($r, @list) = @_;
    die "first arg to pushto must be a ref" unless ref $r;
    if (ref $r eq 'SCALAR') {
        if (defined $$r) {
            $$r = { $$r => 1 };
        } else {
            $$r = { };
        }
    } elsif (ref $r eq 'REF' and ref $$r eq 'HASH') {
        # no-op
    } else {
        die "first arg to pushto must point to a SCALAR or a HASH ref";
    }
    ++$$r->{$_} for @list;
}

my %copiable_refs = map {$_=>1} qw(HASH ARRAY);

sub clone_a_into_b($\$) {
    my ($source, $target_ref) = @_;
    if (ref $source eq "HASH") {
        # clone hash
        $$target_ref = maybe_copy( $source, {} );
    } elsif (ref $source->{$_} eq "ARRAY") {
        # clone array
        $$target_ref = maybe_copy( $source, [] );
    } else {
        # copy scalar, including other sorts of refs
        $$target_ref = $source;
    }
}

sub couple(&@) {
    my ($sub, @list) = @_;
    @list = @{$list[0]} if @list == 1 && ref $list[0] eq 'ARRAY';
    return [ $sub, @list ];
}

sub X(&@) { couple { &{$_[0]}() } @_[ 1 .. $#_ ] }

# sub X(&@) {
#     my ($sub, @list) = @_;
#     @list = @{$list[0]} if @list == 1 && ref $list[0] eq 'ARRAY';
#     return [ $sub, @list ];
# }

# TODO: DOESN'T WORK: FIXME
sub maybe_copy(++) {
    my ($source, $target) = @_;
    #TODO: might not want to die here? Or perhaps wrap a higher sub in eval and catch it.
    die "must be same type of ref (".ref($source)." != ".ref($target).")" unless ref($source) eq ref($target);
    for ($source, $target) {
        #die "must be HASH or ARRAY refs: " . ref($_) unless $copiable_refs{ref $_}
    }
    if (ref $source eq 'HASH') {
        for (sort keys %$source) {
            if ( exists $target->{$_} ) {
                maybe_copy($source->{$_}, $target->{$_});
            } else {
                clone_a_into_b $source->{$_}, $target->{$_};
            }
        }
    } elsif (ref $source eq 'ARRAY') {
        # TODO: Ideally, we'd do a fuzzy sequence match and merge. Need to study those algorithms.

        # for now, just add any elements beyond what target already contains.
        my $tlen = scalar @$target;
        my $slen = scalar @$source;
        if ($tlen < $slen) {
            for (sublist $source, $tlen) {
                my $tmp = undef;
                clone_a_into_b $_, $tmp;
                push @$target, $tmp;
            }
        }
    } else {

    }
    return $target;
}

sub clone_tree(+%) {
    my ($source, %overrides) = @_;
    my %target = %overrides;
    maybe_copy($source, \%target);
}

sub csv_to_rows(@) {
    my @lines = @_;
    my @rows = ();
    for (@lines) {
        chomp;
        my @fields = map { s%^"|"$%%g; s%""%"%g; $_ }
            ( m%(?:^|,)("(?:[^"\n]|"")*"|[^",\n]*)(?:(?=,)|$)%g );
        s%""%"%g for @fields;
        push @rows, [ @fields ] if @fields;
    }
    return @rows;
}

sub csv_file_to_rows($) {
    my ($filename) = @_;
    open local $M::fh, "<$filename" or die "can't open '$filename' for reading";
    my @rows = csv_to_rows(<$M::fh>);
    close $M::fh;
    #D Dumper \@rows;
    return @rows;
}

sub csvquote($) {
    local ($_) = @_;
    s%"%""%g;
    $_ = qq("$_") if /[",\n]/;
    return $_;
}

sub csvline(@) { join(",", map { csvquote $_ } @_) }

sub rows_to_records(@) {
    my ($headers, @rows) = @_;
    map { +{ zip $headers, @$_ } } @rows;
}

sub rotate_rows_to_columns(@) {
    my @columns = @_;
    my @rows = ();
    push @rows, [] for @$columns[0];
    for (@columns) {
        for my $i (0 .. $#$_) {
            push @{$rows[$i]}, $_->[$i];
        }
    }
    return @rows;
}

=head2 records_to_rows
Takes a binary function and a list of records; returns a list of arrayrefs, the first
 of which is a header.

fn($a, $b) will be called for each key/value pair in each record (key / value will be
 passed-in as the [localized] globals $a / $b. If fn returns undef, or if (when it
 returns) the value of $b is undef or a reference, then the key/value pair will be
 removed from the record. Otherwise, the values of $a and $b after fn returns will
 be used as the key/value pair for that field, which will be included in the resulting
 rows.
=cut

sub records_to_rows(&@) {
    my ($fn, @records) = @_;
    return records_to_rows_x($fn, { }, @records);
}

=head2 records_to_rows_x
Same as records_to_rows, but includes a (possibly empty) hashref of options:
  first => [ arrayref of column labels to precede all other columns (in the order they should appear) ]
  last => [ arrayref of column labels to follow all other columns (in the order they should appear) ]
  fieldsort => sub { code reference: should receive a list of column labels and return those labels in sorted order }
=cut

sub records_to_rows_x(&+@) {
    my ($fn, $options, @records) = @_;
    my %fields = my @filtered = ();
    for (@records) {
        my $r = { %$_ };
        for my $k (keys %$r) {
            my $keep = do {
                local *::_ = \$k;
                local *::a = \$k;
                local *::key = \$k;
                local *::b = \($r->{$k});
                local *::val = \($r->{$k});
                local *::value = \($r->{$k});
                &$fn();
            };
            if (defined $keep and defined $r->{$k} and not ref $r->{$k} ) {
                ++$fields{$k};
            } else {
                delete $r->{$k};
            }
        }
        push @filtered, $r;
    }
    # assemble and sequence the fields
    my %sorted_fields = map {$_=>1} sort keys %fields;
    my @fields = ();
    for my $column_set (qw(first last)) {
        if ($options->{$column_set}) {
            delete $sorted_fields{$_} for @{$options->{$column_set}};
        }
    }
    push @fields, @{$options->{'first'}} if $options->{'first'};
    my @to_sort = keys %sorted_fields;
    if ($options->{fieldsort}) {
        my $fn = $options->{fieldsort};
        # D DD \@to_sort;
        @to_sort = &$fn(@to_sort);
        #D DD \@to_sort;
    } else {
        @to_sort = sort @to_sort;
    }
    push @fields, @to_sort;
    push @fields, @{$options->{'last'}} if $options->{'last'};
    return [@fields], map { [ @$_{ @fields } ] } @filtered;
}

# usage: my ($keys, %hash) = ordered_hash ( key1 => "val1", key2 => "val2", ... );
sub ordered_hash(%) {
    die "ordered_hash requires an even number of arguments" if @_ % 2;
    my @keys = ();
    my %hash = ();
    while (@_) {
        my $key = shift;
        my $val = shift;
        push @keys, $key;
        $hash{$key} = $val;
    }
    return [ @keys ], %hash;
}


sub _levenshtein_min {
    my $rv = shift;
    for my $tmp (@_) {
        $rv = $tmp if $tmp < $rv;
    }
    return $rv;
}

sub _editDistance {
    my ($left, $lenLeft, $right, $lenRight) = map { $_, length($_) } @_;

    return $lenRight unless $lenLeft;
    return $lenLeft unless $lenRight;
    
    my $shortLeft  = substr $left,  0, -1;
    my $shortRight = substr $right, 0, -1;
    return _editDistance ($shortLeft, $shortRight) if substr($left, -1) eq substr($right, -1);

    return 1 + _levenshtein_min(
        _editDistance($left,       $shortRight), #insert
        _editDistance($shortLeft,  $right),      #remove
        _editDistance($shortLeft,  $shortRight)  #replace
    );
}
memoize("_editDistance");

sub edit_distance($$) { _editDistance(@_) }

sub similar($$$) { _editDistance(@_[1,2]) <= $_[0] }

# save_ref $filename, {@array or %hash}
sub save_ref($+) {
    my ($file, $r) = @_;
    local $Data::Dumper::Purity = 1;
    to_file($file, Dumper($r));
}

sub restore_ref($+) {
    my ($file, $r) = @_;
    unless ( -e $file ) {
        if (ref $r eq "ARRAY") {
            @$r = ();
        } elsif (ref $r eq "HASH") {
            %$r = ();
        } else {
            die "needs an ARRAY or HASH ref";
        }
        return;
    }
    my $source = slurp $file;
    local $M::VAR1;
    eval "$source";
    if (ref $r eq 'ARRAY') {
        @$r = @$M::VAR1;
    } elsif (ref $r eq 'HASH') {
        %$r = %$M::VAR1;
    } else {
        die "needs an ARRAY or HASH ref";
    }
}

sub ptr(\$) { return $_[0]; }

sub load_index(++@) {
    my ($index, $records, @keylist) = @_;
    $index->{_UPDATE_} ||= sub { D "saw a dupe of ", DD $::new_record };
    $index->{_INSERT_} ||= sub { $$::ptr = $::new_record };
    $index->{_KEYS_} ||= [ @keylist ];
    my $last_key = pop @keylist;
    push @keylist, $last_key;
    for my $r (@$records) {
        my $last_val = $r->{$last_key};
        my $c = $index;
        my $prev_node = undef;
        my $val = undef;;
        for (@keylist) {
            #D "$r->{set}:$r->{number} inserting $_";
            $val = $r->{$_};
            $c->{$val} = {} unless $c->{$val};
        } continue {
            $prev_node = $c;
            $c = $c->{$val};
        }
        if (%$c) {
            local ($::old_record, $::new_record, $::ptr) = ($c, $r, ptr($prev_node->{$last_val}));
            &{ $index->{_UPDATE_} };
        } else {
            local ($::old_record, $::new_record, $::ptr) = ($c, $r, ptr($prev_node->{$last_val}));
            &{ $index->{_INSERT_} };
        }
    }
}

sub search_index(+%) {
    my ($index, %query) = @_;
    my @keylist = @{$index->{__KEYS__}};

    my $c = $index;
    my $prev_node = undef;
    my @matched_keys = ();
    for (@keylist) {
        my $val = $query{$_};
        #D "$query{set}:$query{number} comparing $_ = $val";
        $c = $c->{$val};
        next if $c;
        last;
    } continue {
        $prev_node = $c;
        push @matched_keys, $_;
    }
    if ($c) {
        # found a match
        return $c;
    } else {
        D "no match after ", L(@matched_keys), " for $query{name}: ", Dumper \%query;
        return undef;
    }
}

sub complement(+@) {
    my ($ref, @elements) = @_;
    my %table;
    my $keys;
    if (ref $ref eq "ARRAY") {
        %table = map { $_ => 1 } @$ref;
        $keys = [ @$ref ];
    } elsif (ref $ref eq "HASH") {
        ($keys, %table) = ordered_hash %$ref;
        #TODO: DON'T SORT if the ref is tied!
        @$keys = sort @$keys;
    } else {
        die "need an ARRAY ref or HASH ref: $ref"
    }
    @elements = distinct @elements;
    for (@elements) {
        die "$_ is not in " . L(sort keys %table) unless exists $table{$_};
        delete $table{$_};
    }
    return grep { exists $table{$_} } @$keys;
}

our @caller_fields = qw(
    package
    filename
    line
    subroutine
    hasargs
    wantarray
    evaltext
    is_require
    hints
    bitmask
    hinthash
    );

sub caller_hash($) {
    my $depth = shift;
    my $result = {};
    @$result{@caller_fields} = caller($depth+1);
    return $result;
}

sub check_arg_ref {
    my $opts = do { ref $_[0] eq 'HASH' ? shift @_ : {} };
    my ($argnum, $reftype, @args) = @_;
    $reftype = uc $reftype;
    die ucfirst(ordinal($argnum+1)) . " argument to " . caller_hash(1)->{subroutine} . " must be a value of type ${reftype}REF, but was '$args[$argnum]'"
        unless ref $args[$argnum] eq $reftype;
    return $args[$argnum];
}


{ package M::XML::DumbGenerator;
    sub new {
        my $class = shift;
        return bless { @_ }, $class;
    }
    sub element(@) {
        my $class = shift;
        my %d=();
        $d{name} = shift;
        if (ref($_[0]) eq 'HASH') {
            %d = ( %d, %{shift@_} )
        }
        return bless {
            d => { %d },
            content => [ @_ ],
        }, $class;
    }
    sub _render() {
        my ($self, $t, $depth, $tab) = @_;
        $$t .= $tab x $depth;
        if (ref $self eq 'M::XML::DumbGenerator') {
            $$t .= '<' . $self->{d}{name};
            my $length = scalar( @{$self->{content}} );
            if ($length < 1) {
                $$t .= "/>\n";
            } elsif ($length == 1 && ref($self->{content}[0]) ne 'M::XML::DumbGenerator') {
                $$t .= ">" . $self->{content}[0] . "</" . $self->{d}{name} . ">\n";
            } else {
                $$t .= ">\n";
                for (@{$self->{content}}) {
                    _render($_, $t, $depth+1, $tab);
                }
                $$t .= $tab x $depth;
                $$t .= "</" . $self->{d}{name} . ">\n";
            }
        } elsif (ref $self) {
            die "invalid datatype: ref(\$self) was '".ref($self)."'";
        } else {
            # should consider formatting here
            $$t .= "$self\n";
        }
    }
    sub render() {
        my $self = shift;
        my ($depth, $tab) = @_;
        $depth = 0 unless defined $depth;
        $tab = '  ' unless defined $tab;
        my $textbuffer = "";
        $self->_render(\$textbuffer, $depth, $tab);
        return $textbuffer;
    }
}

sub e(@) { M::XML::DumbGenerator->element(@_) }



=back

=cut

=for html
</article>
</div>
=cut

1; # END M