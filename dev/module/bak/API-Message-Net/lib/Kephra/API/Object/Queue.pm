use v5.14;
use warnings;

package Kephra::API::Object::Queue;
our $VERSION = 0.24;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log is_object looks_like_number/;
################################################################################

sub BUILD         {  # class frontstate backstate max min --> obj              =class: of all items
    return error('need only five optional parameter: class, front and back state, max and min quota') if @_ > 6;
    my $self = shift;
    $self->{item_class} = shift // '';
    $self->{item} = [];
    $self->{front_closed} = $self->{back_closed} = $self->{max} = $self->{min} = 0;
    my ($front, $back, $max, $min) = @_;
    $self->close_front($front) if defined $front;
    $self->close_back($back)   if defined $back;
    $self->set_max_quota($max) if defined $max;
    $self->set_min_quota($min) if defined $min;
    $self;
}

################################################################################

sub is_front_closed { #         --> bool                                       =state:/!open closed/
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{front_closed};
}

sub close_front {     # bool    --> bool
    my ($self, $state) = @_;
    return error('need one parameter - queue front end state: "open" or "closed"') if @_ != 2;
    $self->{front_closed} = $state ? 1 : 0;
}

sub is_back_closed {  #         --> bool                                       =state:/!open closed/
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{back_closed};
}

sub close_back     {  # bool    --> bool
    my ($self, $state) = @_;
    return error('need one parameter - queue back end state: "open" or "closed"') if @_ != 2;
    $self->{back_closed} = $state ? 1 : 0;
}

################################################################################

sub get_min_quota {  #         --> int
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{min};
}

sub set_min_quota {  # int?    --> int                                         !0 (no minimum)
    my ($self, $quota) = @_;
    return error('need one parameter: minimum amount of elements in queue (positive integer)')
        if @_ > 2 or not defined $quota or !looks_like_number($quota) or int($quota) != $quota or $quota < 0;
    return warning('min quota can not be bigger than max quota') if $self->{max} and $self->{max} < $quota;
    $self->{min} = $quota;
}

sub get_max_quota {  #         --> int
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{max};
}

sub set_max_quota {  # int?    --> int|[item]                                  !0 (inf capacity)
    my ($self, $quota) = @_;
    return error('need one parameter: maximum amount of elements in queue (positive integer)')
        if @_ > 2 or not defined $quota or !looks_like_number($quota) or int($quota) != $quota or $quota < 0;
    return warning('max quota can not be smaller than min quota') if $self->{min} and $self->{min} > $quota;
    $self->{max} = $quota;
    $self->_trim_to_max_quota() or $quota;
}

################################################################################

sub item_class   {  #                --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{item_class};
}

sub item_count   {  #                --> int
    return error('need to be called as method with no parameter') if @_ != 1;
    @{$_[0]->{item}}
}

sub item_position { # item           --> int|-1
    my ($self, $item) = @_;
    return error('need one parameter: item present in queue') if @_ != 2;
    for my $pos (reverse 0 .. $#{$self->{item}}) {
        return $pos if $self->{item}[$pos] eq $item;
    }
    -1;
}

sub get_item     {  # pos            --> item
    my ($self, $pos) = @_;
    return error('need one parameter: numeric position of requested element (+/-integer)')
        if @_ != 2 or !looks_like_number($pos) or int($pos) != $pos;
    defined $self->{item}[$pos] ? $self->{item}[$pos] : 0;
}

################################################################################

sub append_item  {  # item unique?   --> [item]|1                              =item that fall out, because others where pushed in
    my ($self, $item, $unique) = @_;
    return error('need one or two parameter: an object derived from agreed class and request that all elements are unique')
        if @_ > 3 or not defined $item;
    return error("second parameter: $item is not derived from $self->{'item_class'}") 
        if $self->{item_class} and (! is_object($item) or ! $item->isa($self->{item_class}));
    return note('tried to append to closed queue') if $self->is_back_closed();
    $self->remove_item($item) if defined $unique and $unique;
    push @{$self->{item}}, $item;
    $self->_trim_to_max_quota() || 1;
}

sub prepend_item {  # item unique?   --> [item]|1                              =1 (success) is implicit when getting items
    my ($self, $item, $unique) = @_;
    return error('need one or two parameter: an object derived from agreed class and request that all elements are unique')
        if @_ > 3 or @_ < 2;
    return error("second parameter: $item is not derived from $self->{'item_class'}") 
        if $self->{item_class} and (! is_object($item) or ! $item->isa($self->{item_class}));
    return note('tried to prepend to closed queue') if $self->is_front_closed();
    $self->remove_item($item) if defined $unique and $unique;
    unshift @{$self->{item}}, $item;
    $self->_trim_to_max_quota() || 1;
}

sub _trim_to_max_quota {
    my ($self) = @_;
    return unless $self->get_max_quota();
    my $surplus = @{$self->{item}} - $self->get_max_quota();
    return 0 unless $surplus > 0;
    splice @{$self->{item}}, 0, $surplus;
}

sub remove_front {  # nr? allornone? --> [item]                                ! all possible if no param 
    my ($self, $demand, $allornone) = @_;
    return error('get two optional parameter: nr. of elements to be removed and bool - if') if @_ > 3 or @_ < 1;
    return error('first parameter has to be a positive number')
        if defined $demand and (!looks_like_number($demand) or int($demand) != $demand or $demand < 1);
    return note('tried to remove items from closed queue') if $self->is_front_closed(); 
    my $available = @{$self->{item}} - $self->get_min_quota();
    $demand = $available unless defined $demand;
    if ($available < $demand) {
        return undef if (defined $allornone and $allornone)
                     or $available == 0;
        $demand = $available;
    }
    splice @{$self->{item}}, 0, $demand;
}

sub remove_item  {  # item           --> int
    my ($self, $item) = @_;
    return error('need one parameter: an object that is currently in the queue') if @_ != 2 or not defined $item;
    my @ret = ();
    for my $pos (reverse 0 .. $#{$self->{item}}) {
        push @ret, (splice @{$self->{item}}, $pos, 1) if $self->{item}[$pos] eq $item;
    }
    @ret ? scalar @ret : undef;
}

################################################################################

sub status       {  #
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = "$self:\n";
    $r .= '  status : front is '.$self->is_front_closed().', back is '.$self->is_back_closed();
    $r .= "  quota : min => $self->{min}, max => $self->{max}\n";
    $r .= '  content: '.$self->item_count()." elements of type $self->{item_class}";
    $r;
}

1;
