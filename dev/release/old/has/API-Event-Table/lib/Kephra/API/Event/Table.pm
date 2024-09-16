use v5.14;
use warnings;

package Kephra::API::Event::Table;
use Kephra::API  qw/:log/;

my %table = ( call => {},   'sub' => {},             path => {},
              active => {before => {}, main => {} , after=> {}},  );



1;

__END__

sub trigger_event {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my $ID = shift;
    my $event = $table{'event'}{$ID};
    $_->{'code'}(@_) for values %{ $event->{'before'} };  # run all calls
    $_->{'code'}(@_) for values %{ $event->{'at'} }; 
    $_->{'code'}(@_) for values %{ $event->{'after'} };
    trigger_event($event->{'parent'}) if exists $event->{'parent'};
    
}

sub freeze_event {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my $ID = shift;
}

sub thaw_event {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my $ID = shift;    
}

sub freeze_all_events { freeze_event() for get_event_names() }
sub thaw_all_events   { thaw_event() for get_event_names() }

### event ######################################################################
sub has_event       { (exists $table{'event'}{$_[0]}) ? 1 : 0 }
sub get_event_names { sort keys %{ $table{'event'} } }

### event action ###############################################################
#sub add_entry            { add_entry_for_caller(1, @_)}
#sub add_entry_for_caller {  #caller/backtrack level, channel data (msg) priority comment

sub create_event_for parent {}
sub create_event {}
sub _create_event {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("channel '$_[0]' was already created")              if has_event($_[0]);
    my $ID = shift;
    my $event = { before => {}, at => {}, after => {}, owner => ''};
    $event->{'owner'} = '';
}

sub rename_event {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my ($ID, $new_ID) = @_;

}

sub change_freeze_state {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my ($ID, $state) = @_;

}


sub delete_event {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
}

### call ######################################################################
sub has_event_call       { (exists $table{'event'}{$_[0]}{'call'}{$_[1]}) ? 1 : 0 }
sub get_event_call_names { sort keys %{ $table{'event'}{$_[0]}{'call'} } }

#coderef, before|at|after => event, autoname => &, [start => alive|frozen|halted]
sub add_call {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my ($ID, $call, $code) = @_;

}
#event, old => new, old => new, old => new
sub rename_call {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my ($ID, $call, $new_name) = @_;

}
#event, old => new, old => new, old => new
sub retach_call {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);    
    my ($ID, $call, $new_event) = @_;

}
# event, [name, name, :all ]
sub remove_call {
    return warning("need a not empty event ID as first parameter") unless $_[0];
    return warning("no channel '$_[0]' was created")               unless has_event($_[0]);
    my ($ID, $call) = @_;
}

# event, [event event] 'slot' => .., | call => ...
################################################################################
sub _has_code { ref $_[0] eq 'HASH' and ref $_[0]->{'code'} eq 'CODE' }
sub _compile {
    my ($hash, $source) = @_;
    if (ref $source eq 'CODE') {$hash->{'code'} = $source }
    else {
        $hash->{'source'} = $source;
        eval '$hash->{"code"} = sub {' . $source . '}';
        return warning("can't compile: $source") if $@;
    }
    1;
}
################################################################################
sub statusreport {
}
################################################################################

1;

__END__

 - global event ID: event.have.such.names
 - are nested (1st event.have.such.names triggers, then event.have.such, then event.have)
 - are private or public (private, can only be triggered from creator name space)
 - create/delete               : events  (eventID, startstatus)
 - freeze/thaw                 : (eventID/callname, ['all'])
 - trigger
 - are 3 states for frozen event: deaf, listen, retrigger
 - slots are:                     before, at, after
 - add/get/rename/delete                : calls   (slot, eventID, startstatus,  name)
 - call-name is module::sub by default

sub send_msg {  # msg channel priority
    return unless ref $channel{$_[1]} eq 'ARRAY';
    if ($_[2]){
        for ( @{ $channel{$_[1]} } [ 0 .. $prio_ptr{ $_[1] }[ $_[2]] ]){
           &$_($_[0]);
    else { &$_( $_[0] ) for @{ $channel{$_[1]} } }
