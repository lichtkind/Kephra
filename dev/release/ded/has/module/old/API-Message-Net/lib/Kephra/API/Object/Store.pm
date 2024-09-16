use v5.14;
use warnings;
no warnings 'experimental::smartmatch';

package Kephra::API::Object::Store;
our $VERSION = 0.10;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log :pkg :test create_counter call_sub/;
use Kephra::API::Call::Dynamic::Template;
use Kephra::API::Object::Queue;
use Kephra::API::Object::Hook;

################################################################################
                        # =classname of items
sub BUILD        {  # self class {getter => setter}? hsize? factory? --> obj
    return error('need one to four parameter: item class, hash with getter => setter pairs, history size (int) and an item factory (call, dynacall or template)')
        if @_ < 2 or 5 < @_;
    my ($self, $item_class, $accessors, $history_size, $factory) = @_;

    return warning("package: $item_class to build store items is not loaded") unless package_loaded($item_class);
    $self->{item}{class} = $item_class;

    $accessors = {} unless defined $accessors;
    return error('the gettter-setter-pairs (second parameter) have to be in a hash') unless ref $accessors eq 'HASH';
    for my $method (keys %$accessors, values %$accessors){
        return warning("package $item_class has no method $method") if $method and not has_sub($item_class, $method);
    }
    $self->{item}{accessor} = $accessors;

    $history_size = 0 unless defined $history_size;
    $self->{item}{history} = int $history_size > 0 ? Kephra::API::Object::Queue->new($item_class, 0, 0, int $history_size) : 0; # front and back of q are open

    return error('did not recieve known item factory type as: Kephra::API::Call Kephra::API::Call::Dynamic'. 
                 'Kephra::API::Call::Template Kephra::API::Call::Dynamic::Template') if defined $factory and not 
        ref $factory ~~ [qw/Kephra::API::Call Kephra::API::Call::Dynamic Kephra::API::Call::Template Kephra::API::Call::Dynamic::Template/];
    if (defined $factory) {$self->{item}{factory} = $factory}
    else                  {$self->{item}{factory} = Kephra::API::Call->new("class $self->item_class() default factory", $self->item_class().'->new(@_)')}

    $self->{item}{by} = { ID => {}, attr => {}, ref => {} };
    $self->{ID_factory} = create_counter(); # creates ID
    $self;
}

################################################################################

sub new_item              {  # [params]? [temp]?   --> item ID                 =temp:code templates for call that creates item
    return error('need one to three parameter: item ID, array ref with constructor params and array ref with code templates') if @_ < 1 or @_ > 3;
    my ($self, $params, $templates) = @_;
    return error('constructor parameter have to come in an array reference (second parameter)') if defined $params and ref $params ne 'ARRAY';
    return error('the one or two code snippets have to come in an array reference (third parameter)') if defined $templates and ref $templates ne 'ARRAY';
    my $item;
    if (defined $templates) {
        return error('do not need second parameter because item factory is a call)') if is_call($self->{item}{factory});
        given ($self->{item}{factory}){
            when (is_dynatemplate($_)) {
                my $dynacall = $self->{item}{factory}->new_dynacall( @$templates );
                return unless is_call($dynacall);
                $item = $dynacall->run( @$params );
            }
            when (is_template($_))     {
                my $call = $self->{item}{factory}->new_call( @$templates );
                return unless is_call($call);
                $item = $call->run( @$params );
            }
        }
    } else {
        given ($self->{item}{factory}){
            when (is_dynatemplate($_)) { $item = $self->{item}{factory}->new_dynacall( @$params )}
            when (is_template($_))     { $item = $self->{item}{factory}->new_call( @$params )}
            when (is_call($_))         { $item = $self->{item}{factory}->run( @$params )}
        }
    }
    $self->add_item($item);
}

sub add_item              {  # item                --> item ID
    my ($self, $item) = @_;
    return error('need one parameter: object of class '.$self->item_class()) if @_ != 2;
    return error("$item is no object of class $self->item_class()") unless is_object($item) and $item->isa($self->item_class());

    my $ID = $self->{ID_factory}->run();
    $self->{item}{by}{ID}{$ID} = $item;
    $self->{item}{by}{ref}{$item} = $ID;
    for my $getter (keys %{$self->{item}{accessor}}){
        $self->_add_item_attribute_association($ID, $getter);
        next unless my $setter = $self->{item}{accessor}{$getter};                                        # install hooks
        Kephra::API::Object::Hook::add_before($item, $setter, $self, 
                            __PACKAGE__.'::_remove_item_attribute_association( $_[2][0],'." '$ID', '$getter')");
        Kephra::API::Object::Hook::add_after($item, $setter, $self, 
                            __PACKAGE__.'::_add_item_attribute_association( $_[2][0],'." '$ID', '$getter')");
    }
    $self->{item}{by}{ID}{$ID}, $ID;
}

sub remove_item           {  # item|ID             --> item
    my ($self, $item_or_ID) = @_;
    return error('need only one parameter: an item stored here or its ID') if @_ != 2;
    my ($item, $ID);
    if (ref $item_or_ID) { ($item, $ID) = ($item_or_ID, $self->get_ID_by_item($item_or_ID)) }
    else                 { ($item, $ID) = ($self->get_item_by_ID($item_or_ID), $item_or_ID) }
    return warning("item: $item_or_ID is not stored here!") unless defined $ID;
    return warning("ID: $item_or_ID is not in use here!") unless $item;
    
    $self->{item}{history}->remove_item($item) if $self->{item}{history};
    for my $getter (keys %{$self->{item}{accessor}}){
        $self->_remove_item_attribute_association($ID, $getter);
        next unless my $setter = $self->{item}{accessor}{$getter};                                  # remove hooks
        Kephra::API::Object::Hook::remove_before($item, $setter, $self);
        Kephra::API::Object::Hook::remove_after($item, $setter, $self);
    }
    delete $self->{item}{by}{ref}{$item};
    delete $self->{item}{by}{ID}{$ID};
}

################################################################################

sub item_class  { #                    --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{item}{class};
}

sub delegate_method       { # name @param   --> [ret]
    my ($self, $method, @param) = @_;
    return error('need at least one parameter: method of item call with its parameter') if @_ < 2;
    return error("package $self->item_class() has no method $method") unless has_sub($self->item_class(), $method);
    my ($sub, @ret) = ($self->item_class().'::'.$method);
    push @ret, call_sub($sub, $_, @param) for values %{$self->{item}{by}{ID}};
    @ret;
}

################################################################################

sub get_item_IDs          { #              --> [ID]
    return error('need to be called as method with no parameter') if @_ != 1;
    sort keys %{$_[0]->{item}{by}{ID}};
}


sub get_ID_by_item        { # item          --> ID
    my ($self, $item) = @_;
    return error('need one parameter: an object (item) that might be stored here') if @_ != 2;
    defined $self->{item}{by}{ref}{$item} ? $self->{item}{by}{ref}{$item} : undef;
}

sub get_item_by_ID        {  # ID           --> obj
    my ($self, $ID) = @_;
    return error('need only one parameter: an item ID') if @_ != 2;
    defined $self->{item}{by}{ID}{$ID} ? $self->{item}{by}{ID}{$ID} : undef;
}

################################################################################

sub item_attributes       {  #              --> [str]
    return error('need to be called as method with no parameter') if @_ != 1;
    sort keys %{$_[0]->{item}{accessor}};
}

sub _add_item_attribute_association {
    my ($self, $ID, $getter) = @_;
    my $item = $self->{item}{by}{ID}{$ID};
    $self->{item}{by}{attr}{$getter}{ call_sub($self->item_class().'::'.$getter, $item) }{$item} = $item;
}

sub _remove_item_attribute_association {
    my ($self, $ID, $getter) = @_;
    return unless ref $self->{item}{by}{attr}{$getter} eq 'HASH';
    my $item = $self->{item}{by}{ID}{$ID};
    my $val = call_sub($self->item_class().'::'.$getter, $item);
    delete $self->{item}{by}{attr}{$getter}{ $val }{$item};
    delete $self->{item}{by}{attr}{$getter}{ $val } unless keys %{$self->{item}{by}{attr}{$getter}{ $val }};
}

sub get_attribute_values  {  # getter       --> [val]
    my ($self, $getter) = @_;
    return error('need one parameter: a registered getter method of item object') if @_ != 2;
    return warning("this store has no registered getter: $getter") unless exists $self->{item}{accessor}{$getter};
    keys %{$self->{item}{by}{attr}{$getter}};
}

sub get_item_by_atttibute {  # getter val   --> [obj]
    my ($self, $getter, $value) = @_;
    return error('need only two parameter: a getter method of item object and its expected value') if @_ != 3;
    return warning("this store has no registered getter: $getter") unless exists $self->{item}{accessor}{$getter};
    if (defined $self->{item}{by}{attr}{$getter} and defined $self->{item}{by}{attr}{$getter}{$value}){
        my @item = (values %{$self->{item}{by}{attr}{$getter}{$value}});
        return @item == 1 ? $item[0] : @item;
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

sub use_item              {  # ID|item      --> 1
    my ($self, $item_or_ID) = @_;
    return error('need one parameter: item that is in this store or its ID') if @_ != 2;
    return warning("this store has no history") unless $self->{item}{history};
    if (ref $item_or_ID) {
        return warning("item: $item_or_ID is not stored here!") unless defined $self->get_ID_by_item($item_or_ID);
        } else {
        return warning("ID: $item_or_ID is not in use here!") unless defined $self->get_item_by_ID($item_or_ID);
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
    $r .= '  content: '.(scalar($self->list_item_IDs())).' elements of type '.$self->{item}{class};
    $r .= '  item factory :'.($self->{item}{factory}->get_source())."\n";
    if (keys %{$self->{item}{'accessor'}}) {
        $r .= "  tracked attributes:\n";
        $r .= "    getter: $_ - setter: $self->{item}{accessor}{$_}\n" for keys %{$self->{accessor}};
    } else {
        $r .= "  no item attribute tracking\n";
    }
    $r .= $self->{'item'}{'history'}
        ? '  item access history has memory size of '.$self->{'item'}{'history'}->get_max_quota()."\n"
        : "  no item access history tracking\n";
    $r;
}

1;
