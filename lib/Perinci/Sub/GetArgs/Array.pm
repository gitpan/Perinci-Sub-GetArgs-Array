package Perinci::Sub::GetArgs::Array;

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use Data::Clone;
use Data::Sah;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_args_from_array);

our $VERSION = '0.11'; # VERSION

our %SPEC;

$SPEC{get_args_from_array} = {
    v => 1.1,
    summary => 'Get subroutine arguments (%args) from array',
    description => <<'_',

Using information in metadata's 'args' property (particularly the 'pos' and
'greedy' arg type clauses), extract arguments from an array into a hash
\%args, suitable for passing into subs.

Example:

    my $meta = {
        v => 1.1,
        summary => 'Multiply 2 numbers (a & b)',
        args => {
            a => {schema=>'num*', pos=>0},
            b => {schema=>'num*', pos=>1},
        }
    }

then 'get_args_from_array(array=>[2, 3], meta=>$meta)' will produce:

    [200, "OK", {a=>2, b=>3}]

_
    args => {
        array => {
            schema => ['array*' => {}],
            req => 1,
            description => <<'_',

NOTE: array will be modified/emptied (elements will be taken from the array as
they are put into the resulting args). Copy your array first if you want to
preserve its content.

_
        },
        meta => {
            schema => ['hash*' => {}],
            req => 1,
        },
        allow_extra_elems => {
            schema => ['bool' => {default=>0}],
            summary => 'Allow extra/unassigned elements in array',
            description => <<'_',

If set to 1, then if there are array elements unassigned to one of the arguments
(due to missing 'pos', for example), instead of generating an error, the
function will just ignore them.

_
        },
    },
};
sub get_args_from_array {
    my %input_args = @_;
    my $ary  = $input_args{array} or return [400, "Please specify array"];
    my $meta = $input_args{meta};
    if ($meta) {
        my $v = $meta->{v} // 1.0;
        return [412, "Only metadata version 1.1 is supported, given $v"]
            unless $v == 1.1;
    }
    my $args_p    = $input_args{_args_p}; # allow us to skip cloning
    if (!$args_p) {
        $args_p = clone($meta->{args} // {});
        while (my ($a, $as) = each %$args_p) {
            $as->{schema} = Data::Sah::normalize_schema($as->{schema} // 'any');
        }
    }
    my $allow_extra_elems = $input_args{allow_extra_elems} // 0;
    return [400, "Please specify meta"] if !$meta && !$args_p;
    #$log->tracef("-> get_args_from_array(), array=%s", $array);

    my $args = {};

    for my $i (reverse 0..@$ary-1) {
        #$log->tracef("i=$i");
        while (my ($a, $as) = each %$args_p) {
            my $o = $as->{pos};
            if (defined($o) && $o == $i) {
                if ($as->{greedy}) {
                    my $type = $as->{schema}[0];
                    my @elems = splice(@$ary, $i);
                    if ($type eq 'array') {
                        $args->{$a} = \@elems;
                    } else {
                        $args->{$a} = join " ", @elems;
                    }
                    #$log->tracef("assign %s to arg->{$a}", $args->{$a});
                } else {
                    $args->{$a} = splice(@$ary, $i, 1);
                    #$log->tracef("assign %s to arg->{$a}", $args->{$a});
                }
            }
        }
    }

    return [400, "There are extra, unassigned elements in array: [".
                join(", ", @$ary)."]"] if @$ary && !$allow_extra_elems;

    [200, "OK", $args];
}

1;
#ABSTRACT: Get subroutine arguments from array

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::GetArgs::Array - Get subroutine arguments from array

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use Perinci::Sub::GetArgs::Array;

 my $res = get_args_from_array(array=>\@ary, meta=>$meta, ...);

=head1 DESCRIPTION

This module provides get_args_from_array(). This module is used by, among
others, L<Perinci::Sub::GetArgs::Argv>.

This module uses L<Log::Any> for logging framework.

This module has L<Rinci> metadata.

=head1 FUNCTIONS

None are exported by default, but they are exportable.


None are exported by default, but they are exportable.

=head2 get_args_from_array(%args) -> [status, msg, result, meta]

Using information in metadata's 'args' property (particularly the 'pos' and
'greedy' arg type clauses), extract arguments from an array into a hash
\%args, suitable for passing into subs.

Example:

    my $meta = {
        v => 1.1,
        summary => 'Multiply 2 numbers (a & b)',
        args => {
            a => {schema=>'num*', pos=>0},
            b => {schema=>'num*', pos=>1},
        }
    }

then 'getI<args>from_array(array=>[2, 3], meta=>$meta)' will produce:

    [200, "OK", {a=>2, b=>3}]

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_extra_elems> => I<bool> (default: 0)

Allow extra/unassigned elements in array.

If set to 1, then if there are array elements unassigned to one of the arguments
(due to missing 'pos', for example), instead of generating an error, the
function will just ignore them.

=item * B<array>* => I<array>

NOTE: array will be modified/emptied (elements will be taken from the array as
they are put into the resulting args). Copy your array first if you want to
preserve its content.

=item * B<meta>* => I<hash>

=back

Return value:

Returns an enveloped result (an array). First element (status) is an integer containing HTTP status code (200 means OK, 4xx caller error, 5xx function error). Second element (msg) is a string containing error message, or 'OK' if status is 200. Third element (result) is optional, the actual result. Fourth element (meta) is called result metadata and is optional, a hash that contains extra information.

=head1 TODO

I am not particularly happy with the duplication of functionality between this
and the 'args_as' handler in L<Perinci::Sub::Wrapper>. But the later is a code
to generate code, so I guess it's not so bad for now.

=head1 SEE ALSO

L<Perinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-GetArgs-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Sub-GetArgs-Array>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-GetArgs-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
