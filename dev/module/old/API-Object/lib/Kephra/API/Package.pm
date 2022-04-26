use v5.16;
no warnings;

package Kephra::API::Package;
use Exporter 'import';
our @EXPORT_OK = qw/package_loaded count_sub has_sub call_sub/;
our %EXPORT_TAGS = (all  => [@EXPORT_OK]);

sub count_sub {
    return unless $_[0];
    no strict 'refs';
    keys *{"$_[0]::"}{HASH};
}

sub package_loaded {
    return unless $_[0];
    count_sub($_[0]) > 0 ? 1 : 0;
}

sub has_sub {
    return unless @_;
    no strict 'refs';
    defined *{join '::', @_}{'CODE'} ? 1 : 0;
}

sub call_sub {
    my ($full_sub_name, @params) = @_;
    return unless defined $full_sub_name;
    no strict 'refs';
    &{$full_sub_name}(@params);
}

1;
