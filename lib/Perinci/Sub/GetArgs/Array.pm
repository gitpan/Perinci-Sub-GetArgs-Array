package Perinci::Sub::GetArgs::Array;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Data::Clone;
use Data::Sah;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_args_from_array);

our $VERSION = '0.09'; # VERSION

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
        },
        spec => {
            schema => ['hash*' => {}],
            req => 1,
        },
        allow_extra_elems => {
            schema => ['bool' => {default=>0}],
            summary => 'Allow extra/unassigned elements in array',
            description => <<'_',

If set to 1, then if there are array elements unassigned to one of the arguments
(due to missing 'arg_pos', for example), instead of generating an error, the
function will just ignore them.

_
        },
    },
};
sub get_args_from_array {
    my %input_args = @_;
    # don't assign this to $array, we have @array too, avoid error-prone
    $input_args{array} or return [400, "Please specify array"];
    my $meta      = $input_args{meta};
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

    my @array = @{$input_args{array}};
    my $args = {};

    for my $i (reverse 0..$#array) {
        #$log->tracef("i=$i");
        while (my ($a, $as) = each %$args_p) {
            my $o = $as->{pos};
            if (defined($o) && $o == $i) {
                if ($as->{greedy}) {
                    my $type = $as->{schema}[0];
                    my @elems = splice(@array, $i);
                    if ($type eq 'array') {
                        $args->{$a} = \@elems;
                    } else {
                        $args->{$a} = join " ", @elems;
                    }
                    #$log->tracef("assign %s to arg->{$a}", $args->{$a});
                } else {
                    $args->{$a} = splice(@array, $i, 1);
                    #$log->tracef("assign %s to arg->{$a}", $args->{$a});
                }
            }
        }
    }

    return [400, "There are extra, unassigned elements in array: [".
                join(", ", @array)."]"] if @array && !$allow_extra_elems;

    [200, "OK", $args];
}

1;
#ABSTRACT: Get subroutine arguments from array


=pod

=head1 NAME

Perinci::Sub::GetArgs::Array - Get subroutine arguments from array

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use Perinci::Sub::GetArgs::Array;

 my $res = get_args_from_array(array=>\@ary, meta=>$meta, ...);

=head1 DESCRIPTION

This module provides get_args_from_array() (and gencode_get_args_from_array(),
upcoming). This module is used by, among others, L<Perinci::Sub::GetArgs::Argv>.

This module uses L<Log::Any> for logging framework.

This module has L<Rinci> metadata.

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head1 TODO

I am not particularly happy with the duplication of functionality between this
and the 'args_as' handler in L<Perinci::Sub::Wrapper>. But the later is a code
to generate code, so I guess it's not so bad for now.

=head1 SEE ALSO

L<Perinci>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

