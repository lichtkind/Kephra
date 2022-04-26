

package Kephra::API::Class::Attribute;
use constant { ROOT_KEY => ':ATTRIBUTE' };
use Exporter 'import';
our @EXPORT_OK = qw/attribute/;
use Kephra::API::Data::Type;



sub attribute {
    my ($name, $def) = @_;
    return unless @_ == 2;
    return unless ref $def eq 'HASH';
    my( $package) = caller.'::';
    my %attr = ();
    no strict 'refs';
    no warnings 'redefine';
    # check para nr
    # check ref
    # check type
    *{$package.$attr{get}} = sub { };
    *{$package.$attr{set}} = sub { };
    use strict;
    use warnings;
}

1;

__DATA__
   
   sub get_state { 
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{state};
}

