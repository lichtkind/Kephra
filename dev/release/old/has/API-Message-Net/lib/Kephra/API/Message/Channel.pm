use v5.14;
use warnings;

package Kephra::API::Message::Channel;
our $VERSION = 0.01;
use parent      qw/Kephra::API::Object/;
use Kephra::API qw/:log blessed is_int/;
use Kephra::API::Message;
use Kephra::API::Object::Store;

my $default_size = 20;

################################################################################

sub BUILD          { # name type? state? size? --> obj                         =self:/source target filter msgs/
    my ($self, $name, $type, $state, $size) = @_;
    return error('need one, max. four parameter: item class, hash with getter => setter pairs, history size and item constructor code') if @_ < 2 or 5 < @_;

    $self->{name} = $name;
    $self->{type} = (defined $type and $type eq 'out') ? 'out' : 'in';
    $self->{msg_accepted} = 0;
    $self->{msg_rejected} = 0;
    
    $self->{template} = Kephra::API::Call::Template->new('', 'my $msg = $_ = shift;');
    $self->{msgs}     = Kephra::API::Object::Queue->new('Kephra::API::Message', 0, 0, $default_size);  # open is default state
    $self->{filter}   = Kephra::API::Object::Store->new('Kephra::API::Call', {}, 0, $self->{template});
    $self->{target}   = Kephra::API::Object::Store->new('Kephra::API::Call', {}, 0, $self->{template});
    
    $self->set_state($state) if defined $state;    
    $self->set_size($size) if defined $size;
    $self;
}

sub name           {  #         --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{name};
}

sub type           {  #         --> str                                        =type:/in out/
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{type};    
}

################################################################################

sub get_state      {  #         --> state                                      =state:/!open hold closed/
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{msgs}->is_back_closed() ? 'closed' : $_[0]->{msgs}->is_front_closed() ? 'hold' : 'open';
}

sub set_state      {  # state   --> 1
    my ($self, $state) = @_;
    return error('need one parameter - channel state: "open", "hold" or "closed"') if @_ > 2 or not defined $state;
    return warning('channel states are: "open", "hold" or "closed"') if $state ne 'open' and $state ne 'closed' and $state ne 'hold';
    $self->{msgs}->close_back( $state eq 'closed' ? 1 : 0 );
    $self->{msgs}->close_front( $state eq 'open' ? 0 : 1 );
    if ($state eq 'open') {
        $self->{target}->delegate_method('run', $_) for $self->{msgs}->remove_front();
    }
    1;
}

sub get_size       {  #         --> int
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{msgs}->get_max_quota();
}

sub set_size       {  # int     --> 1
    my ($self, $size) = @_;
    return error("accept one optional parameter: channel size, an integer > 0, defaults to $default_size") if @_ < 1 or 2 < @_;
    return warning('channel size has to be a positive integer') if defined $size and (not is_int($size) or $size < 0);
    $self->{msgs}->set_max_quota( defined $size ? $size : $default_size );
}

################################################################################

sub add_filter     {  # src     --> FID
    return error('need one parameter : source code of a channel filter') unless @_ == 2;
    my ($self, $source) = @_;
    $self->{filter}->new_item([ ref $source eq 'Regexp' ? '$msg->content() =~ '.$source : $source ]);
}

sub get_filter_IDs {  #         --> [FID]
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{filter}->get_item_IDs();
}

sub get_filter     {  # FID     --> call
    my ($self, $filter_ID) = @_;
    return error('need one parameter : an active filter ID') unless @_ == 2;
    $self->{filter}->get_item_by_ID($filter_ID);
}

sub remove_filter  {  # FID     --> 1
    return error('need one parameter : a used filter ID') unless @_ == 2;
    my ($self, $filter_ID) = @_;
    return warning("there is no filter with ID: $filter_ID") unless $self->{filter}->get_item_by_ID($filter_ID);
    $self->{filter}->remove_item($filter_ID);
    1;
}

################################################################################

sub add_target     {  # srcl srcr? --> TID
    return error('need one parameter : source code of a channel target') unless @_ == 2;
    my ($self, $source) = @_;
    $self->{target}->new_item([$source]);  
}

sub get_target_IDs {  #         --> [TID]
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{target}->get_item_IDs();
}

sub get_target     {  # TID     --> call
    my ($self, $target_ID) = @_;
    return error('need one parameter : an active target ID') unless @_ == 2;
    $self->{target}->get_item_by_ID($target_ID);
}

sub remove_target  {  # TID     --> 1
    return error('need one parameter : an active target ID') unless @_ == 2;
    my ($self, $target_ID) = @_;
    return warning("there is no target with ID: $target_ID") unless $self->{target}->get_item_by_ID($target_ID);
    $self->{target}->remove_item($target_ID);
    1;   
}

################################################################################

sub append_message {  # msg     --> int
    my ($self, $msg) = @_;
    return error('need one parameter : source code of a channel target') unless @_ == 2;
    return warning('message sent to channel '.$self->name().' was not an object of class '.$self->{msgs}->item_class())
        unless blessed($msg) eq $self->{msgs}->item_class();
    return note('sent message to muted channel '.$self->name()) if $self->{msgs}->get_back_state() eq 'closed';
    for my $ret ($self->{filter}->delegate_method('run', $msg)) {
        if ($ret){ $self->{msg_rejected}++; return 0; }
    }
    $msg->set_channel($self->type(), $self->name());
    $self->{msgs}->get_front_state() eq 'open'
        ? $self->{target}->delegate_method('run', $msg)
        : $self->{msgs}->append_item($msg);
    ++$self->{msg_accepted};
}

sub message_count  {  # kind?   --> int
    return error('accept one optional parameter - kind of message: "recieved", "accepted" or "rejected"') if @_ < 1 or 2 < @_;
    my ($self, $kind) = @_;
    return warning('parameter has to be: none, "recieved", "accepted" (default) or "rejected"')
        if defined $kind and $kind ne 'recieved' and $kind ne 'accpted' and $kind ne 'rejected';
    return $self->{msg_accepted} if not defined $kind or $kind eq 'accepted';
    return $self->{msg_rejected} if                      $kind eq 'rejected';
    $self->{msg_accepted} + $self->{msg_rejected};
}

sub remove_messages{  #         --> [msgs]
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my @ret = ();
    push @ret, $self->{msgs}->remove_item(0) for 1 .. $self->{msgs}->item_count;
    @ret;
}

################################################################################

sub status         {  #         --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = "$self:\n";
    $r;
}

1;
