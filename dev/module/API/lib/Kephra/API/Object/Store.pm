use v5.14;
use warnings;

package Kephra::API::Object::Store;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log :pkg :test create_counter call_sub/;
use Kephra::API::Call::Template;
use Kephra::API::Object::Queue;
use Kephra::API::Object::Hook;

################################################################################
                        # =classname of items
sub BUILD        {  # self class {getter => setter}? hsize? factory? --> obj
    return error('need one, max. four parameter: item class, hash with getter => setter pairs, history size and item constructor code') if @_ < 2 or 6 < @_;
    my ($self, $item_class, $accessors, $history_size, $item_constructor, $right_code) = @_;

    return warning("package: $item_class to build store items is not loaded") unless package_loaded($item_class);
    $self->{item_class} = $item_class;

    $accessors = {} unless defined $accessors;
    return error('the gettter-setter-pairs (second parameter) have to be in a hash') unless ref $accessors eq 'HASH';
    for my $method (keys %$accessors, values %$accessors){
        return warning("package $item_class has no method $method") if $method and not has_sub($item_class, $method);
    }
    $self->{accessor} = $accessors;
    $self->{item} = { by_ID => {}, by_attr => {}, by_ref => {} };

    $history_size = 3 unless defined $history_size;
    $self->{item}{history} = $history_size > 0 ? Kephra::API::Object::Queue->new($item_class, 'open', 'open', $history_size) : 0;

    if (defined $right_code)         { $self->{item_factory} = Kephra::API::Call::Template->new($item_constructor, $right_code) }
    elsif (defined $item_constructor){ $self->{item_factory} = is_call($item_constructor) ? $item_constructor : Kephra::API::Call->new($item_constructor) }
    else                             { $self->{item_factory} = Kephra::API::Call->new($item_class.'->new(@_)') }

    $self->{counter} = create_counter();
    
    $self;
}

################################################################################

sub new_item              {  # [params]? [temp]?   --> ID
    return error('need one to three parameter: item ID, array ref with constructor params and array ref with code templates') if @_ < 1 or @_ > 3;
    my ($self, $params, $templates) = @_;
    return error('constructor parameter have to come in an array reference (second parameter)') if defined $params and ref $params ne 'ARRAY';
    return error('the one or two code snippets have to come in an array reference (third parameter)') if defined $templates and ref $templates ne 'ARRAY';
    my $item;
    if  (is_call($self->{item_factory})) { $item = $self->{item_factory}->run( @$params ) }
    elsif (not defined $templates)       { $item = $self->{item_factory}->new_call( @$params ) }
    else                                 { $item = $self->{item_factory}->new_call( @$templates )->run( @$params ) }
    $self->add_item($item);
}

sub add_item              {  # item                --> item ID
    my ($self, $item) = @_;
    return error('need one parameter: object of class '.$self->{item_class}) if @_ != 2;
    return error("$item is no object of class $self->{item_class}") unless is_object($item) and $item->isa($self->{item_class});

    my $ID = $self->{counter}->run();
    $self->{item}{by_ID}{$ID} = $item;
    $self->{item}{by_ref}{$item} = $ID;
    for my $getter (keys %{$self->{accessor}}){
        $self->_add_item_attribute_association($ID, $getter);
        next unless my $setter = $self->{accessor}{$getter};                                        # install hooks
        Kephra::API::Object::Hook::add_before($item, $setter, $self, 
                            __PACKAGE__.'::_remove_item_attribute_association( $_[2][0],'." '$ID', '$getter')");
        Kephra::API::Object::Hook::add_after($item, $setter, $self, 
                            __PACKAGE__.'::_add_item_attribute_association( $_[2][0],'." '$ID', '$getter')");
    }
    $self->{item}{by_ID}{$ID}, $ID;
}

sub remove_item           {  # item|ID             --> item
    my ($self, $item_or_ID) = @_;
    return error('need only one parameter: an item stored here or its ID') if @_ != 2;
    my ($item, $ID);
    if (ref $item_or_ID) {
        return warning("item: $item_or_ID is not stored here!") unless defined $self->{item}{by_ref}{$item_or_ID};
        ($item, $ID) = ($item_or_ID, $self->get_ID_by_item($item_or_ID),);
        } else {
        return warning("ID: $item_or_ID is not in use here!") unless defined $self->{item}{by_ID}{$item_or_ID};
        ($item, $ID) = ($self->get_item_by_ID($item_or_ID), $item_or_ID);
    }
    $self->{item}{history}->remove_item($item) if $self->{item}{history};
    for my $getter (keys %{$self->{accessor}}){
        $self->_remove_item_attribute_association($ID, $getter);
        next unless my $setter = $self->{accessor}{$getter};                                  # remove hooks
        Kephra::API::Object::Hook::remove_before($item, $setter, $self);
        Kephra::API::Object::Hook::remove_after($item, $setter, $self);
    }
    delete $self->{item}{by_ref}{$item};
    delete $self->{item}{by_ID}{$ID};
}

################################################################################

sub get_item_class  { #                    --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{item_class};
}

sub list_item_IDs         {  #              --> [ID]
    return error('need to be called as method with no parameter') if @_ != 1;
    sort keys %{$_[0]->{item}{by_ID}};
}


sub get_ID_by_item        { # item          --> ID
    my ($self, $item) = @_;
    return error('need one parameter: an object (item) that might be stored here') if @_ != 2;
    defined $self->{item}{by_ref}{$item} ? $self->{item}{by_ref}{$item} : undef;
}

sub get_item_by_ID        {  # ID           --> obj
    my ($self, $ID) = @_;
    return error('need only one parameter: an item ID') if @_ != 2;
    defined $self->{item}{by_ID}{$ID} ? $self->{item}{by_ID}{$ID} : undef;
}

################################################################################

sub delegate_method       { # name @param   --> [ret]
    my ($self, $method, @param) = @_;
    return error('need at least one parameter: method of item call with its parameter') if @_ < 2;
    return error("package $self->{item_class} has no method $method") unless has_sub($self->{item_class}, $method);
    my ($sub, @ret) = ("$self->{item_class}::$method");
    push @ret, call_sub($sub, $_, @param) for values %{$self->{item}{by_ID}};
    @ret;
}

sub list_item_attributes  {  #              --> [str]
    return error('need to be called as method with no parameter') if @_ != 1;
    sort keys %{$_[0]->{accessor}};
}


sub _add_item_attribute_association {
    my ($self, $ID, $getter) = @_;
    my $item = $self->{item}{by_ID}{$ID};
    $self->{item}{by_attr}{$getter}{ call_sub("$self->{item_class}::$getter", $item) }{$item}++;
}

sub _remove_item_attribute_association {
    my ($self, $ID, $getter) = @_;
    return unless ref $self->{item}{by_attr}{$getter} eq 'HASH';
    my $item = $self->{item}{by_ID}{$ID};
    delete $self->{item}{by_attr}{$getter}{ call_sub("$self->{item_class}::$getter", $item) }{$item};
}

sub list_item_by_atttibute { # getter val   --> [obj]
    my ($self, $getter, $value) = @_;
    return error('need only two parameter: a getter emthod of item object and its expected value') if @_ != 3;
    return warning("this store has no registered getter: $getter") unless exists $self->{accessor}{$getter};
    if (defined $self->{item}{by_attr}{$getter} and defined $self->{item}{by_attr}{$getter}{$value}){
        return (keys %{$self->{item}{by_attr}{$getter}{$value}});
    }
    0;
}

################################################################################

sub has_history           {  #              --> bool
    return error('need to be called as method with no parameter') if @_ != 1;
    ref $_[0]->{item}{history} eq 'Kephra::API::Object::Queue' ? 1 : 0;
}

sub get_latest_item       {  # nr?          --> obj|0
    my ($self, $pos) = @_;
    return error('need only one optional parameter: position in queue of lately used store items') if @_ < 1 or 2 < @_;
    return warning("this store has no history") unless $self->{item}{history};
    $pos = 0 unless defined $pos;
    $self->{item}{history}->get_item($pos);
}

sub use_item              {  # ID|item      --> 1|undef
    my ($self, $item_or_ID) = @_;
    return error('need one parameter: item that is in this store or its ID') if @_ != 2;
    return warning("this store has no history") unless $self->{item}{history};
    if (ref $item_or_ID) {
        return warning("item: $item_or_ID is not stored here!") unless defined $self->{item}{by_ref}{$item_or_ID};
        } else {
        return warning("ID: $item_or_ID is not in use here!") unless defined $self->{item}{by_ID}{$item_or_ID};
        $item_or_ID = $self->get_item_by_ID($item_or_ID); # $item_or_ID is an item, guaranteed
    }
    $self->{item}{history}->prepend_item($item_or_ID, 'unique');
    1;
}

################################################################################

sub status                {  #              --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = __PACKAGE__." $self:\n";
    $r .= '  content: '.(scalar($self->list_item_IDs())).' elements of type '.$self->{item_class};
    $r .= '  item factory :'.($self->{'item_factory'}->get_source())."\n";
    if (keys %{$self->{'accessor'}}) {
        $r .= "  tracked attributes:\n";
        $r .= "    getter: $_ - setter: $self->{accessor}{$_}\n" for keys %{$self->{accessor}};
    } else {
        $r .= "  no item attribute tracking\n";
    }
    $r .= $self->{'item'}{'history'}
        ? '  item access history has memory size of '.$self->{'item'}{'history'}->get_max_quota()."\n"
        : "  no item access history tracking\n";
    $r;
}

1;
