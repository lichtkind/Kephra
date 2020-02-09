use v5.16;
use warnings;

package Kephra::Base::Data;
our $VERSION = 0.01;
use Scalar::Util qw/blessed/;
use Kephra::Base::Data::Type;
use Exporter 'import';
our @EXPORT_OK = qw/clone_item clone_list/;

my %copied_reftype   = ('' => 1, Regexp => 1, CODE => 1, FORMAT => 1, IO => 1, GLOB => 1, LVALUE => 1);

################################################################################

sub clone_item {_clone($_[0],{})}# data --> data
sub _clone {
    my ($data, $dict) = @_;
    return unless defined $data;

    my ($class, $ref) = (blessed($data), ref $data);
    return $data if $copied_reftype{$ref};   # ref to readonly data
    return $dict->{$data} if $dict->{$data}; # reuse ref to already copied data

    my $ret = $ref eq 'HASH' ? {} : $ref eq 'ARRAY' ? [] : '';
    $dict->{$data} = $ret if $ref eq 'HASH' or $ref eq 'ARRAY';
    if    ($ref eq 'HASH')   { $ret->{$_} = _clone($data->{$_}, $dict) for keys %$data }
    elsif ($ref eq 'ARRAY')  { push @$ret, _clone($_, $dict) for @$data  }
    elsif ($ref eq 'REF')    { $ret = \_clone($$data, $dict);  $dict->{$data} = $ret;}
    elsif ($ref eq 'SCALAR'
        or $ref eq 'VSTRING'){ my $val = $$data; $ret = \$val }
    else                     { } # ?

    $class ? bless($ret, $class) : $ret;
}



sub clone_list { #               [data] --> [data]
    my @ret;
    push @ret, clone_item($_) for @_;
    @ret;
}

################################################################################

1;
