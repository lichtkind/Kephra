
use v5.14;
use warnings;

package Kephra::API::Message::Net;
our $VERSION = 0.02;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log/;
use Kephra::API::Object::Store;
use Kephra::API::Message;
use Kephra::API::Message::Channel;

################################################################################

sub BUILD                {  #                        --> obj                   =self:/channel/
    my ($self, $state) = @_;
    $self->{channel} = Kephra::API::Object::Store->new('Kephra::API::Message::Channel', {type => '', name => ''});
    $self->{related} = {};   # from => { name => target_ID }
    $self->{state} = 'open';
    $self->set_state($state) if defined $state;
    $self;
}

################################################################################

sub get_state            {  #                        --> state                 =state:/!open, closed, shut_down/
    return error('need to be called as method with no parameter') if @_ != 1;# =shut_down: close and delete all msg
    $_[0]->{state};
}

sub set_state            {  # state                  --> 1
    return error('need one parameter - message net state: "open", "closed" or "shut_down"') unless @_ == 2;
    my ($self, $state) = @_;
    say "-- $self";
    return warning('known message net states are "open", "closed" or "shut_down"')
        if $state ne 'open' or $state ne 'closed' or $state ne 'shut_down';
    if ($state eq 'shut_down') {
        $self->{channel}->get_item_by_ID($_)->remove_messages() for $self->{channel}->get_item_IDs();
    }
    $self->{state} = $state;
}

################################################################################

sub create_channel       {  # CID type? state? size? --> channel               =CID:names(str), ot internal ID
    return error('need at least one parameter: message channel name') if @_ < 1 or 5 < @_;
    my ($self, $name, @params) = @_;
    return warning("there is already a channel named: $name") if $self->get_channel($name);
    $self->{related}{$name} = {};
    #($self->{channel}->new_item([$name, @params]))[0];
    $self->{channel}->new_item([$name, @params]);
}

sub get_channel_names    {  # type?                  --> [CID]
    return error('accepts one optional parameter: channel type ("in" or "out")') if @_ < 1 or 2 < @_;
    my ($self, $type) = @_;
    return warning('only channel types are: ("in" or "out")') if defined $type and $type ne 'in' and $type ne 'out';
    defined $type 
        ? map {$_->name()} $self->{channel}->get_item_by_atttibute('type', $type)
        : $self->{channel}->get_attribute_values('name');
}

sub get_channel          {  # CID                    --> channel
    return error('need one parameter: name of a channel') unless @_ == 2;
    my ($self, $name) = @_;
    $self->{channel}->get_item_by_atttibute('name', $name);
}

sub delete_channel       {  # CID                    --> 1
    return error('need one parameter: name of a channel') unless @_ == 2;
    my ($self, $name) = @_;
    my $channel = $self->get_channel($name);
    return warning("there is no channel named: $name") unless $channel;
    $self->disconnect_channel($name);
    delete $self->{related}{$name};
    $self->{channel}->remove_item($channel);
    1;
}

################################################################################

sub connect_channel      {  # inCID outCID           --> 1
    return error('need two parameter: names of an input channel and an output one') unless @_ == 3;
    my ($self, $in_name, $out_name) = @_;
    my $in_channel = $self->get_channel($in_name);
    my $out_channel = $self->get_channel($out_name);
    return warning("there is no input channel named: $in_name") unless $in_channel and $in_channel->type() eq 'in';
    return warning("there is no output channel named: $out_name") unless $out_channel and $out_channel->type() eq 'out';
    $self->{related}{$in_name}{$out_name} = $in_channel->add_target('Kephra::API::Message::Channel::append_message($out_channel,$msg);');
    $self->{related}{$out_name}{$in_name} = $in_channel;
    1;
}

sub get_connected_channel{  # CID                    --> [CID]
    return error('need one parameter: name of a channel') unless @_ == 2;
    my ($self, $name) = @_;
    return warning("there is no channel named: $name") unless $self->get_channel($name);
    keys %{$self->{related}{$name}};
}

sub disconnect_channel   {  # inCID outCID?          --> int
    return error('need two parameter: names of an input channel and an output one')  if @_ < 2 or 3 < @_;
    my ($self, $in_name, $out_name) = @_;
    if (defined $out_name){
        my $in_channel = $self->get_channel($in_name);
        return warning("there is no input channel named: $in_name") unless $in_channel and $in_channel->type() eq 'in';
        my $out_channel = $self->get_channel($out_name);
        return warning("there is no output channel named: $out_name") unless $out_channel and $out_channel->type() eq 'out';
        $in_channel->remove_target( $self->{related}{$in_name}{$out_name} );
        delete $self->{related}{$in_name}{$out_name};
        delete $self->{related}{$out_name}{$in_name};
        return 1;
    } else {
        my $channel = $self->get_channel($in_name);
        return warning("there is no channel named: $in_name") unless $channel;
        my $nr = scalar keys %{$self->{related}{$in_name}};
        if ($channel->type() eq 'in') {
            for ($self->get_connected_channel($in_name)) {
                $channel->remove_target( $self->{related}{$in_name}{$_} );
                delete $self->{related}{$in_name}{$_};
                delete $self->{related}{$_}{$in_name};
            }
        } else {
            for ($self->get_connected_channel($in_name)) {
                $self->get_channel($_)->remove_target( $self->{related}{$_}{$in_name} );
                delete $self->{related}{$in_name}{$_};
                delete $self->{related}{$_}{$in_name};
            }
        }
        $self->{related}{$in_name} = {};
        return $nr;
    }
}

################################################################################

sub send_message         {  # CID str|hash           --> 1
    my ($self, $name, $raw_message) = @_;
    return error('need two parameter: name of an input channel and the message(string or hash)') unless @_ == 3;
    return warning('message net is not open') if $self->get_state() ne 'open';
    my $channel = $self->get_channel($name);
    return warning("there is no input channel named: $name") unless $channel and $channel->type() eq 'in';
    my $msg = Kephra::API::Message->new($raw_message) or return;
    $self->get_channel($name)->append_message($msg);
    1;
}

################################################################################

sub status               {  #                        --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = "$self:\n";
    $r;
}

1;
