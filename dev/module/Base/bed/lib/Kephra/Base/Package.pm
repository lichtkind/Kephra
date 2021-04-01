use v5.20;
no warnings qw/experimental redefine/;

package Kephra::Base::Package;
our $VERSION = 1.1;
use Exporter 'import';
our @EXPORT_OK = qw/package_loaded count_sub has_sub has_hash has_array get_sub get_hash get_array set_sub set_hash set_array call_sub sub_caller/;
our %EXPORT_TAGS = (all  => [@EXPORT_OK]);

sub package_loaded {
    return unless $_[0];
    my $pkg = shift;
    $pkg =~ s|::|/|g;
    $INC{"$pkg.pm"} ? 1 : 0;
}

sub count_sub {
    return unless $_[0];
    no strict 'refs';
    keys %{*{"$_[0]::"}{HASH}};
}

sub call_sub {
    my ($full_sub_name, @params) = @_;
    return unless defined $full_sub_name;
    no strict 'refs';
    &{$full_sub_name}(@params);
}

sub has_sub {
    return unless @_;
    no strict 'refs';
    defined *{join '::', @_}{CODE} ? 1 : 0;
}
sub has_hash {
    return unless @_;
    no strict 'refs';
    defined *{join '::', @_}{HASH} ? 1 : 0;
}
sub has_array {
    return unless @_;
    no strict 'refs';
    defined *{join '::', @_}{ARRAY} ? 1 : 0;
}

sub get_sub {
    my ($pkg, $sub_name) = @_;
    $pkg .= '::'.$sub_name if defined $sub_name;
    no strict 'refs';
   *{$pkg}{'CODE'};
}
sub get_hash {
    my ($pkg, $hash_name) = @_;
    $pkg .= '::'.$hash_name if defined $hash_name;
    no strict 'refs';
   *{$pkg}{'HASH'};
}
sub get_array {
    my ($pkg, $array_name) = @_;
    $pkg .= '::'.$array_name if defined $array_name;
    no strict 'refs';
   *{$pkg}{'ARRAY'};
}

sub set_sub {
    my ($pkg, $sub_name, $code) = @_;
    if (defined $code){$sub_name = $pkg.'::'.$sub_name}
    else              {$code = $sub_name; $sub_name = $pkg }
    return 0 unless ref $code eq 'CODE';
    no strict 'refs';
    *{$sub_name} = $code;
    1;
}
sub set_hash {
    my ($pkg, $hash_name, $hash) = @_;
    if (defined $hash){$hash_name = $pkg.'::'.$hash_name}
    else              {$hash = $hash_name; $hash_name = $pkg }
    return 0 unless ref $hash eq 'HASH';
    no strict 'refs';
    *{$hash_name} = $hash;
    1;
}
sub set_array {
    my ($pkg, $array_name, $array) = @_;
    if (defined $array){$array_name = $pkg.'::'.$array_name}
    else               {$array = $array_name; $array_name = $pkg }
    return 0 unless ref $array eq 'ARRAY';
    no strict 'refs';
    *{$array_name} = $array;
    1;
}

sub sub_caller {
    my($depth, $file, $line, $caller, $pos, $sub, $package) = (shift // 1);
    while (1) {
        ++$depth;
        ($package, $file, $line, $caller) = ((caller($depth-1))[0,1,2], (caller($depth))[3]);
        last unless $caller;
        $pos = rindex($caller, '::');
        $package = substr($caller, 0, $pos);
        $sub     = substr($caller, $pos+2);
        next if substr($sub, 0, 1) eq '_';
        next if $package eq 'Kephra::API' and $sub;
        last;
    }
    ($package, $sub, $file, $line);
}
1;
