use v5.16;
use warnings;

# create methods, accessor stubs are created from Kephra::Base::Class::Instance::Attribute
# organize their hooks

package Kephra::Base::Class::Builder::Accessor;
our $VERSION = 0.03;
use Kephra::Base::Package qw/set_sub call_sub/;
use Kephra::Base::Class::Builder::Method;

my $universal_getter = sub{Kephra::Base::Class::Attribute::get($_[0])};
my (%setter, %resetter);

################################################################################
sub create_attribute_accessors {
    my ($class, $attribute, $type, $class_types) = @_;
    my $callback = $class_types->check_callback($type);
    my $default = $class_types->default_value($type);

    return 0 unless ref $callback;
    $resetter{$class}{$type} = sub{set($_[0], $default )} unless ref $resetter{$class}{$type};
    $setter{$class}{$type} = sub{   $callback->($_[1], Kephra::Base::Class::Instance::get_access_self($_[0]))
                         or Kephra::Base::Class::Instance::Attribute::set(@_[0,1])} unless ref $setter{$class}{$type};

    Kephra::Base::Package::set_sub( Kephra::Base::Class::Scope::name('attribute',$class,$attribute,'get'), $universal_getter);
    Kephra::Base::Package::set_sub( Kephra::Base::Class::Scope::name('attribute',$class,$attribute,'set'),  $setter{$type});
    Kephra::Base::Package::set_sub( Kephra::Base::Class::Scope::name('attribute',$class,$attribute,'reset'), $resetter{$type});
    1;
}

################################################################################
sub create_constructor { # aka new
    my ($class, $method, $params, $code) = @_;
    return "constructor definition needs at least class and method name " unless defined $method;
    if (not defined $params){ # setting minimal default destructor (just creates object)
        $params = Kephra::Base::Class::Method::Signature::parse('');
        $code = sub {};
    }
    return "malformed definition of constructor method $class::$method"
        if ref $params ne 'HASH' or (defined $code and ref $code ne 'CODE');
    my $class_types = Kephra::Base::Class::get_types($class);
    my $name = "$class::$method";
    return "can not add constructor method $name to class $class without types" unless ref $class_types;
    my ($incheck, $outcheck) = Kephra::Base::Class::Method::Signature::create_type_check($params, $class_types, $name);
    return $incheck unless ref $incheck and ref $outcheck;
    my $body;
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    if (defined $code){ # normal or minimal constuctor
        Kephra::Base::Class::Method::Argument::set_methods($class, $method, $params->{input});
        $body = sub {
            my $class = shift;
            my $self = Kephra::Base::Class::Instance::create($class);
            return $self unless ref $self;
            my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
            my $err_or_params = $incheck->($access_scope_self , @_);
            unless (ref $err_or_params) {Kephra::Base::Class::Instance::delete($self); return $err_or_params}
            my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
            $anchor->{'BEFORE'}->($self,$parameter);
            my $hook_result = $anchor->{'BEFORE_AND'}->($self,$parameter);
            my $retval = $code->($access_scope_self, $parameter);
            my $error = $outcheck->($retval, $access_scope_self);
            if ($error) {$$self = $error;  $retval = undef}
            else        {$$self = ''}
            $anchor->{'AFTER'}->($self, $parameter, $retval);
            $anchor->{'AND_AFTER'}->($self, $parameter, $retval, $hook_result);
            Kephra::Base::Class::Method::Argument::delete($parameter);
            if ($error) {Kephra::Base::Class::Instance::delete($self); return $error}
            $self;
        }
    } else { # maping default constructor
        $body = sub {
            my $class = shift;
            my $self = Kephra::Base::Class::Instance::create($class);
            return $self unless ref $self;
            my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
            my $err_or_params = $incheck->($access_scope_self, @_);
            unless (ref $err_or_params) {Kephra::Base::Class::Instance::delete($self); return $err_or_params}
            my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
            $anchor->{'BEFORE'}->($self,$parameter);
            my $hook_result = $anchor->{'BEFORE_AND'}->($self,$parameter);
            my $attributes = Kephra::Base::Class::get_attributes($class);
            my $class_name = ref $access_scope_self;
            for (@{$params->{input}}){
                if ($_->[0] eq 'PARAMETER'){
                         Kephra::Base::Package::call_sub( $class_name.'::'.$_->[1], $access_scope_self, @{$err_or_params->{$_->[1]}} ) if $err_or_params->{$_->[1]};
                } else { Kephra::Base::Class::Attribute::set(Kephra::Base::Class::Instance::get_attribute($self, $_->[1]), $err_or_params->{$_->[1]})}
            }
            $anchor->{'AFTER'}->($self, $parameter);
            $anchor->{'AND_AFTER'}->($self, $parameter, $hook_result);
            $self;
        }
    }
    Kephra::Base::Package::set_sub($_, $body) for Kephra::Base::Class::Scope::included('public', $class, $method);
    0;
}
sub create_default_constructor { # aka new
# TODO mapping only methods
    my ($class, $method) = @_;
    Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    0;
}
sub create_reconstructor { # aka restate
    my ($class, $method, $params) = @_;
    Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    0;
}
sub create_introspector { # aka state
    my ($class, $method) = @_;
    Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    0;
}
sub create_reproductor { # aka clone
    my ($class, $method, $introspector, $reconstructor) = @_;
    return "class $class misses state and restate methods, can not create clone"
        unless Kephra::Base::Package::has_sub(Kephra::Base::Class::Scope::name('public', $class, $introspector))
        and Kephra::Base::Package::has_sub(Kephra::Base::Class::Scope::name('public', $class, $reconstructor));
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    my $body = sub {
        my $self = shift;
        my $public_self = Kephra::Base::Class::Instance::get_public_self($self);
        return undef unless ref $public_self;
        $anchor->{'BEFORE'}->($public_self);
        my $hook_result = $anchor->{'BEFORE_AND'}->($public_self);
        my $new_self = Kephra::Base::Package::call_sub(
            "$class::$reconstructor", $class, Kephra::Base::Package::call_sub("$class::$introspector", $self));
        $anchor->{'AFTER'}->($public_self, $new_self);
        $anchor->{'AND_AFTER'}->($public_self, $new_self, $hook_result);
    };
    Kephra::Base::Package::set_sub($_, $body) for Kephra::Base::Class::Scope::included('public', $class, $method);
    0;
}
sub create_destructor {  # aka destroy
    my ($class, $method, $params, $code) = @_;
    return "destructor definition needs at least class and method name " unless defined $method;
    if (not defined $params){ # default destructor
        $params = Kephra::Base::Class::Method::Signature::parse('');
        $code = sub {};
    }
    return "malformed definition of destructor method $class::$method" unless ref $params eq 'HASH' and ref $code eq 'CODE';
    my $class_types = Kephra::Base::Class::get_types($class);
    my $name = "$class::$method";
    return "can not add destructor method $name to class $class without types" unless ref $class_types;
    my ($incheck, $outcheck) = Kephra::Base::Class::Method::Signature::create_type_check($params, $class_types, $name);
    return $incheck unless ref $incheck and ref $outcheck;
    Kephra::Base::Class::Method::Argument::set_methods($class, $method, $params->{input});
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    my $body =  sub {
        my $self = shift;
        my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
        return undef unless ref $access_scope_self;
        my $err_or_params = $incheck->($access_scope_self , @_);
        unless (ref $err_or_params) {$$self = $err_or_params; return undef}
        my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
        $anchor->{'BEFORE'}->($access_scope_self);
        my $hook_result = $anchor->{'BEFORE_AND'}->($access_scope_self);
        my $retval = $code->($access_scope_self, $parameter);
        my $error = $outcheck->($retval, $access_scope_self);
        if ($error) {$$self = $error;  $retval = undef}
        else        {$$self = ''}
        $anchor->{'AFTER'}->($access_scope_self, $parameter, $retval);
        $anchor->{'AND_AFTER'}->($access_scope_self, $parameter, $retval, $hook_result);
        Kephra::Base::Class::Method::Argument::delete($parameter);
        Kephra::Base::Class::Instance::delete($self);
        $retval;
    };
    Kephra::Base::Package::set_sub($_, $body) for Kephra::Base::Class::Scope::included('public', $class, $method);
    0;
}
sub create {
    my ($class, $method, $params, $code, $scope) = @_;
    return "malformed definition of method $class::$method" unless ref $params eq 'HASH'
                                                               and ref $code eq 'CODE' and defined $scope
                                                               and Kephra::Base::Class::Scope::is($scope);
    my $name = "$class::$method";
    my $class_types = Kephra::Base::Class::get_types($class);
    die "can not add method $name to class $class without types" unless ref $class_types;
    my ($incheck, $outcheck) = Kephra::Base::Class::Method::Signature::create_type_check($params, $class_types, $name);
    return $incheck unless ref $incheck and ref $outcheck;
    Kephra::Base::Class::Method::Argument::set_methods($class, $method, $params->{input});
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    my $body = sub {
        my $self = shift;
        my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
        return undef unless ref $access_scope_self;
        my $private_self = Kephra::Base::Class::Instance::get_private_self($self);
        my $err_or_params = $incheck->($access_scope_self , @_);
        unless (ref $err_or_params) {$$self = $err_or_params; return undef}
        my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
        $anchor->{'BEFORE'}->($private_self, $parameter);
        my $hook_result = $anchor->{'BEFORE_AND'}->($private_self, $parameter);
        my $retval = $code->($private_self, $parameter);
        my $error = $outcheck->($retval, $access_scope_self);
        if ($error) {$$self = $error; $retval = undef}
        else        {$$self = ''}
        $anchor->{'AFTER'}->($private_self, $parameter, $retval);
        $anchor->{'AND_AFTER'}->($private_self, $parameter, $retval, $hook_result);
        Kephra::Base::Class::Method::Argument::delete($parameter);
        $retval;
    };
    Kephra::Base::Package::set_sub($_, $body) for Kephra::Base::Class::Scope::included($scope, $class, $method);
    0;
}

sub create_multi {
    my ($class, $method, $detail_list) = @_;
    my (@priv_incheck, @pub_incheck, @priv_outcheck, @pub_outcheck, @priv_code, @pub_code);
    return "multi method $class::$method needs a list of method definitions"
        unless ref $detail_list eq 'ARRAY' or @$detail_list == 0;
    my $name = "$class::$method";
    my $class_types = Kephra::Base::Class::get_types($class);
    return "can not add multi method $name to class $class without types" unless ref $class_types;
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    for (@$detail_list){
        return 0 unless ref $_ eq 'ARRAY';
        my ($params, $code, $scope) = @$_;
        return 0 unless ref $params eq 'HASH'and ref $code eq 'CODE' and defined $scope and $scope;
        my ($incheck, $outcheck) = Kephra::Base::Class::Method::Signature::create_type_check($params, $class_types, $name);
        return $incheck unless ref $incheck and ref $outcheck;
        push @priv_incheck, $incheck;
        push @priv_outcheck, $outcheck;
        push @priv_code, $code;
        if ($scope eq 'public'){
            push @pub_incheck, $priv_incheck[-1];
            push @pub_outcheck, $priv_outcheck[-1];
            push @pub_code, $code;
        }
        Kephra::Base::Class::Method::Argument::set_methods($class, $method, $params->{input});
    }
    my $priv_code = sub {
        my $self = shift;
        my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
        return undef unless ref $access_scope_self;
        my $private_self = Kephra::Base::Class::Instance::get_private_self($self);
        my ($alt, $err_or_params);
        for (0 .. $#priv_incheck){
            $alt = $_;
            $err_or_params = $priv_incheck[$_]->($access_scope_self, @_);
            last if ref $err_or_params;
        }
        unless (ref $err_or_params) {$$self = $err_or_params; return undef}
        my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
        $anchor->{'BEFORE'}->($private_self, $parameter);
        my $hook_result = $anchor->{'BEFORE_AND'}->($private_self, $parameter);
        my $retval = $priv_code[$alt]->($private_self, $parameter);
        my $error = $priv_outcheck[$alt]->($retval, $access_scope_self);
        if ($error) { $$self = $error; $retval = undef }
        else        { $$self = '' }
        $anchor->{'AFTER'}->($private_self, $parameter, $retval);
        $anchor->{'AND_AFTER'}->($private_self, $parameter, $retval, $hook_result);
        Kephra::Base::Class::Method::Argument::delete($parameter);
        $retval;
    };
    Kephra::Base::Package::set_sub($_, $priv_code) for Kephra::Base::Class::Scope::included('private', $class, $method);
    return 0 if @pub_code == 0;

    Kephra::Base::Package::set_sub( Kephra::Base::Class::Scope::name('public', $class, $method), sub {
        my $self = shift;
        my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
        return undef unless ref $access_scope_self;
        my $private_self = Kephra::Base::Class::Instance::get_private_self($self);
        my ($alt, $err_or_params);
        for (0 .. $#pub_incheck){
            $alt = $_;
            $err_or_params = $pub_incheck[$_]->($access_scope_self, @_);
            last if ref $err_or_params;
        }
        unless (ref $err_or_params) {$$self = $err_or_params; return undef}
        my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
        $anchor->{'BEFORE'}->($private_self, $parameter);
        my $hook_result = $anchor->{'BEFORE_AND'}->($private_self, $parameter);
        my $retval = $pub_code[$alt]->($private_self, $parameter);
        my $error = $pub_outcheck[$alt]->($retval, $access_scope_self);
        if ($error) { $$self = $error; $retval = undef }
        else        { $$self = '' }
        $anchor->{'AFTER'}->($private_self, $parameter, $retval);
        $anchor->{'AND_AFTER'}->($private_self, $parameter, $retval, $hook_result);
        Kephra::Base::Class::Method::Argument::delete($parameter);
        $retval;
    });
    0;
}
sub create_accessor { #   --> bool
    my ($class, $method, $attribute, $detail_list) = @_;
    return "malformed data to define method $class::$method"
        unless ref $detail_list eq 'ARRAY' or @$detail_list == 0 or @$detail_list > 2;
    for (@$detail_list){ return 0 unless ref $_ eq 'ARRAY' and @$_ == 3 and Kephra::Base::Class::Scope::is($_->[2]) }
    my $name = "$class::$method";
    my ($getset_scope, @incheck, @outcheck);
    if (@$detail_list == 2){ # getter/setter with tighter scope will be created later
        $getset_scope = Kephra::Base::Class::Scope::tighter($detail_list->[1][2],$detail_list->[0][2]);
        $detail_list = [$detail_list->[1], $detail_list->[0]] if $getset_scope eq $detail_list->[0][2];
    }
    my ($params, $code, $scope) = @{$detail_list->[0]};
    my $class_types = Kephra::Base::Class::get_types($class);
    return "can not add accessor method $name to class $class without types" unless ref $class_types;
    ($incheck[0], $outcheck[0]) = Kephra::Base::Class::Method::Signature::create_type_check($params, $class_types, $name);
    return $incheck[0] unless ref $incheck[0]and ref $outcheck[0];
    Kephra::Base::Class::Method::Argument::set_methods($class, $method, $params->{input});
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    my $body = sub {
        my $self = shift;
        my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
        return undef unless ref $access_scope_self;
        my $attr_ref = Kephra::Base::Class::Instance::get_attribute($self, $attribute);
        my $err_or_params = $incheck[0]->($access_scope_self , @_);
        unless (ref $err_or_params) {$$self = $err_or_params; return undef}
        my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
        $anchor->{'BEFORE'}->($access_scope_self, $parameter, $attr_ref);
        my $hook_result = $anchor->{'BEFORE_AND'}->($access_scope_self, $parameter, $attr_ref);
        my $retval = $code->($access_scope_self, $parameter, $attr_ref);
        my $error = $outcheck[0]->($retval, $access_scope_self);
        if ($error) { $$self = $error; $retval = undef }
        else        { $$self = '' }
        $anchor->{'AFTER'}->($access_scope_self, $parameter, $attr_ref, $retval);
        $anchor->{'AND_AFTER'}->($access_scope_self, $parameter, $attr_ref, $retval, $hook_result);
        Kephra::Base::Class::Method::Argument::delete($parameter);
        $retval;
    };
    Kephra::Base::Package::set_sub($_, $body) for Kephra::Base::Class::Scope::included($scope, $class, $method);
    return 0 if @$detail_list == 1;

    $params = $detail_list->[1][0];
    $code = [$detail_list->[0][1], $detail_list->[1][1]];
    $incheck[1] = Kephra::Base::Class::Method::Signature::create_input_type_check($params, $class_types, $name);
    return 0 unless ref $incheck[1];
    $outcheck[1] = Kephra::Base::Class::Method::Signature::create_output_type_check($params, $class_types, $name);
    return 0 unless ref $outcheck[1];
    Kephra::Base::Class::Method::Argument::set_methods($class, $method, $params->{input});
    my $mbody = sub { # proper error alarm
        my $self = shift;
        my $alt = 0;
        my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
        return undef unless ref $access_scope_self;
        my $attr_ref = Kephra::Base::Class::Instance::get_attribute($self, $attribute);
        my $err_or_params = $incheck[0]->($access_scope_self , @_);
        $err_or_params = $incheck[++$alt]->($access_scope_self , @_) unless ref $err_or_params;
        unless (ref $err_or_params) {$$self = $err_or_params; return undef}
        my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
        $anchor->{'BEFORE'}->($access_scope_self, $parameter, $attr_ref);
        my $hook_result = $anchor->{'BEFORE_AND'}->($access_scope_self, $parameter, $attr_ref);
        my $retval = $code->[$alt]->($access_scope_self, $parameter, $attr_ref);
        my $error = $outcheck[$alt]->($retval, $access_scope_self);
        if ($error) { $$self = $error; $retval = undef }
        else        { $$self = '' }
        $anchor->{'AFTER'}->($access_scope_self, $parameter, $attr_ref, $retval);
        $anchor->{'AND_AFTER'}->($access_scope_self, $parameter, $attr_ref, $retval, $hook_result);
        Kephra::Base::Class::Method::Argument::delete($parameter);
        $retval;
    };
    Kephra::Base::Package::set_sub($_, $mbody) for Kephra::Base::Class::Scope::included($getset_scope, $class, $method);
    0;
}
sub create_default_accessors {
    my ($class, $method, $attribute, $type, $scope) = @_; #
    return 0 unless ref $scope eq 'HASH';
    for (values %$scope){return 0 unless Kephra::Base::Class::Scope::is($_)}
    my $class_types = Kephra::Base::Class::get_types($class);
    return 0 unless ref $class_types;
    my $callback = $class_types->check_callback( $type );
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    if ($scope->{get}) {
        my $code = sub {
            my $attr = Kephra::Base::Class::Instance::get_attribute($_[0], $attribute);
            return undef unless ref $attr;
            if (@_ != 1) {${$_[0]} = "attribute $attribute of class $class getter $method takes no argument"; return undef}
            $anchor->{'BEFORE'}->(@_);
            my $hook_result = $anchor->{'BEFORE_AND'}->(@_);
            my $retval = Kephra::Base::Class::Instance::Attribute::get($attr);
            $anchor->{'AFTER'}->(@_, $retval);
            $anchor->{'AND_AFTER'}->(@_, $retval, $hook_result);
            $retval;
        };
        Kephra::Base::Package::set_sub($_, $code) for Kephra::Base::Class::Scope::included($scope->{get}, $class, $method);
    }
    if ($scope->{set}){
        my $code = sub {
            my $attr = Kephra::Base::Class::Instance::get_attribute($_[0], $attribute);
            return undef unless ref $attr;
            if (@_ != 2) {${$_[0]} = "attribute $attribute of class $class setter $method takes only one argument"; return undef}
            my $error = $callback->($_[1], Kephra::Base::Class::Instance::get_access_self($_[0]));
            if ($error){${$_[0]} = $error; return undef}
            $anchor->{'BEFORE'}->(@_);
            my $hook_result = $anchor->{'BEFORE_AND'}->(@_);
            my $retval = Kephra::Base::Class::Instance::Attribute::set( $attr, $_[1]);
            $anchor->{'AFTER'}->(@_, $retval);
            $anchor->{'AND_AFTER'}->(@_, $retval, $hook_result);
            $retval;
        };
        Kephra::Base::Package::set_sub($_, $code) for Kephra::Base::Class::Scope::included($scope->{set}, $class, $method);
    }
    if ($scope->{get} and $scope->{set}){
        my $code = sub {
            my $attr = Kephra::Base::Class::Instance::get_attribute($_[0], $attribute);
            return undef unless ref $attr;
            if (@_ > 2 or @_ == 0) {${$_[0]} = "attribute $attribute of class $class getter/setter $method takes no or one argument"; return undef}
            elsif (@_ == 2){
                my $error = $callback->($_[1], Kephra::Base::Class::Instance::get_access_self($_[0]));
                if ($error){${$_[0]} = $error; return undef}
            }
            $anchor->{'BEFORE'}->(@_);
            my $hook_result = $anchor->{'BEFORE_AND'}->(@_);
            my $retval = (@_ == 1)
                ? Kephra::Base::Class::Instance::Attribute::get($attr)
                : Kephra::Base::Class::Instance::Attribute::set($attr, $_[1]);
            $anchor->{'AFTER'}->(@_, $retval);
            $anchor->{'AND_AFTER'}->(@_, $retval, $hook_result);
            $retval;
        };
        Kephra::Base::Package::set_sub($_, $code) for Kephra::Base::Class::Scope::included(
                    Kephra::Base::Class::Scope::tighter($scope->{get}, $scope->{set}), $class, $method);
    }
    0;
}
sub create_delegator {
    my ($class, $method, $params, $code, $attribute, $scope) = @_; #
    return "malformed definition of a delegation method $class::$method"
        unless ref $params eq 'HASH' and ref $code eq 'CODE' and defined $scope and Kephra::Base::Class::Scope::is($scope);
    my $name = "$class::$method";
    my $class_types = Kephra::Base::Class::get_types($class);
    die "can not add method $name to class $class without types" unless ref $class_types;
    my ($incheck, $outcheck) = Kephra::Base::Class::Method::Signature::create_type_check($params, $class_types, $name);
    return $incheck unless ref $incheck and ref $outcheck;
    Kephra::Base::Class::Method::Argument::set_methods($class, $method, $params->{input});
    my $anchor = Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    my $body = sub {
        my $self = shift;
        my $access_scope_self = Kephra::Base::Class::Instance::get_access_self($self);
        return undef unless ref $access_scope_self;
        my $attr = Kephra::Base::Class::Instance::get_attribute($self, $attribute);
        my $err_or_params = $incheck->($access_scope_self , @_);
        unless (ref $err_or_params) {$$self = $err_or_params; return undef}
        my $parameter = Kephra::Base::Class::Method::Argument::create($class, $method, $err_or_params);
        $anchor->{'BEFORE'}->($access_scope_self, $parameter, $attr);
        my $hook_result = $anchor->{'BEFORE_AND'}->($access_scope_self, $parameter, $attr);
        my $retval = $code->($access_scope_self, $parameter, $attr);
        my $error = $outcheck->($retval, $access_scope_self);
        if ($error) {$$self = $error; $retval = undef}
        else        {$$self = ''}
        $anchor->{'AFTER'}->($access_scope_self, $parameter, $attr, $retval);
        $anchor->{'AND_AFTER'}->($access_scope_self, $parameter, $attr, $retval, $hook_result);
        Kephra::Base::Class::Method::Argument::delete($parameter);
        $retval;
    };
    Kephra::Base::Package::set_sub($_, $body) for Kephra::Base::Class::Scope::included($scope, $class, $method);
    0;
}
sub create_default_delegator {
    my ($class, $method, $attr_class, $attr_method, $attribute, $scope) = @_;
    return "malformed definition of a default delegation method $class::$method"
        unless defined $scope and Kephra::Base::Class::Scope::is($scope);
    my $code = Kephra::Base::Package::get_sub($attr_class, $attr_method);
    my $body = sub {$code->(Kephra::Base::Class::Instance::get_attribute(shift, $attribute), @_)};
    Kephra::Base::Package::set_sub($_, $body) for Kephra::Base::Class::Scope::included($scope, $class, $method);
    Kephra::Base::Class::Method::Hook::create_anchor($class, $method);
    0;
}

################################################################################
1;
