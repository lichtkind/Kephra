use v5.14;
use warnings;
no warnings qw/experimental::smartmatch/;

package Kephra::API::MessageNet;
use Kephra::API  qw/:log/;
use Time::HiRes qw/gettimeofday/;

my %net = (); # IN channel get msg from modules, OUT get msg IN (sources) and send to targets
my $global_close = my $global_mute = 0;                          # global states

################################################################################
#   Net
################################################################################

sub state               { # state?            getter/setter                    =state:open, close, mute, shut_down(mute+del all)
    return error('need max. 1 (optional) parameter: new global network state') if @_ > 1;
    my $state = lc shift;
    if (defined $state) {
        return warning('unknown state') if $state ne 'open' and $state ne 'close' and $state ne 'mute' and $state ne 'shutdown';
        $global_close = $global_mute = 0;
        $global_mute = 1 if $state eq 'mute' or $state eq 'shutdown';
        $global_close = 1 if $state eq 'close';
        if ($state eq 'shutdown'){
            trim_channel($_, 0) for list_channel();
            note('global shut down of the message network !');
        } elsif ($state eq 'open'){
            for (list_channel()){
                _channel_send_msg_to_all_target($_) if channel_state($_) eq 'open';
            }
        }
    } else {
        $global_mute ? 'mute' : $global_close ? 'close' : 'open';
    }
}

################################################################################
#   Channel
################################################################################

sub create_channel       { # CID type?, quota?, packagesize?, state? --> 1/0   =state:/open close mute/
    return error('need max. 5, min. 1 parameter: channel, type, quota, package size and state') if @_ > 5;
    my $channel_ID = shift;
    return error('need a channel ID as fist parameter') unless defined $channel_ID;
    return warning("channel $channel_ID already exists") if defined $net{$channel_ID};
    my $type = shift // 'in';
    $net{$channel_ID}{'source'} = {} if lc $type eq 'out';
    $net{$channel_ID}{'target'} = {};
    $net{$channel_ID}{'quota'}  = int (shift // 20);
    $net{$channel_ID}{'package_size'} = shift // 1;
    my $state  = lc( shift // 'open' );
    $state = 'open' if $state ne 'open' and $state ne 'close' and $state ne 'mute';
    $net{$channel_ID}{'close'} = $state eq 'close' ? 1 : 0;
    $net{$channel_ID}{'mute'} = $state eq 'mute' ? 1 : 0;
    $net{$channel_ID}{'filter'} = { map => {}, grep => {}};
    $net{$channel_ID}{'cursor_pos'} = 0;
    $net{$channel_ID}{'message'} = [];
    1;
}

sub has_channel          { # CID --> 1|0
    return error('need only 1 parameter: channel_ID') if @_ > 1;
    my $channel_ID = shift;
    return error('need a channel ID as first parameter') unless defined $channel_ID;
    exists $net{$channel_ID} ? 1 : 0;
}

sub list_channel         { #     --> [CID]
    return error('need no parameter') if @_ > 0;
    sort keys %net;
}

sub delete_channel       { # CID --> Hashref(channel)|0
    return error('need only 1 parameter: channel_ID)') if @_ > 1;
    return 0 unless _approve_channel_ID($_[0]);
    delete $net{ (shift) };
}

################################################################################
#   Channel Properties
################################################################################

sub channel_type         { # CID      --> in|out   getter                     =out:source exists
    return error('need only 1 parameter: channel_ID') if @_ > 1;
    return unless _approve_channel_ID($_[0]);
    exists $net{ (shift) }{'source'} ? 'out' : 'in' ;
}

sub channel_quota        { # CID int? --> int      getter/setter
    return error('need max. 2 parameter: channel_ID and optionally the new quota') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $quota) = @_;
    if (defined $quota) {
        return warning('quota has to be at least as large as the package size: '.$net{$channel_ID}{'package_size'})
        if $quota < $net{$channel_ID}{'package_size'};
        $net{$channel_ID}{'quota'} = $quota;
    } else { $net{$channel_ID}{'quota'} }
}

sub package_size         { # CID int? --> int      getter/setter
    return error('need max. 2 parameter: channel_ID and optionally the new package size') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $size) = @_;
    if (defined $size) {
        return warning('size has to be a at least 1') if $size < 1;
        $net{$channel_ID}{'package_size'} = $size;
        $net{$channel_ID}{'quota'} = $size if  $size > $net{$channel_ID}{'quota'};
    } else {              $net{$channel_ID}{'package_size'}         }
}

sub channel_state        { # CID int? --> int      getter/setter
    return error('need max. 2 parameter: channel_ID and optionally the desired channel state') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $state) = @_;
    if (defined $state) {
        $state = lc $state;
        $net{$channel_ID}{'close'} = $state eq 'close' ? 1 : 0;
        $net{$channel_ID}{'mute'} = $state eq 'mute' ? 1 : 0;
        _channel_send_msg_to_all_target($channel_ID) if $state eq 'open';
    } else {
        return 'mute' if $net{$channel_ID}{'mute'} ;
        return 'close' if $net{$channel_ID}{'close'};
        return 'open';
    }
}

################################################################################
#   Channel IO
################################################################################

sub add_source           { # CID SID  --> Hashref(source)|0
    return error('need only 2 parameter: channel_ID (type out) and channel_ID of new source (in)') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    return warning("$channel_ID is an IN channel") unless defined $net{$channel_ID}{'source'};
    my $source_ID = shift;
    return error('need a channel source ID as second parameter') unless defined $source_ID;
    return warning("there is no channel named $source_ID ") unless defined $net{$source_ID};
    return warning("source channel $source_ID is an OUT channel") if defined $net{$source_ID}{'source'};
    return warning("OUT channel $channel_ID has already $source_ID as source")
        if defined $net{$channel_ID}{'source'}{$source_ID};
    $net{$channel_ID}{'source'}{$source_ID} = {map => {}, grep => {}};
    $net{$source_ID}{'target'}{$channel_ID} = $net{$channel_ID};
    1;
}

sub has_source           { # CID SID  --> 1|0
    return error('need only 2 parameter: channel_ID (type out) and channel_ID of source (in)') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $source_ID) = @_;
    (exists $net{$channel_ID}{'source'} and exists $net{$channel_ID}{'source'}{$source_ID}) ? 1 : 0; 
}

sub list_sources         { # CID      --> [SID]
    return error('need only 1 parameter: channel_ID (type out)') if @_ > 1;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    return warning("$channel_ID is not an OUT channel") unless defined $net{$channel_ID}{'source'};
    sort keys %{$net{$channel_ID}{'source'}};
}

sub remove_source        { # CID SID  --> Hashref(source)
    return error('need only 2 parameter: channel_ID (type out) and channel_ID of source (in)') if @_ > 2;
    return 0 unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    return warning("$channel_ID is not an OUT channel") unless defined $net{$channel_ID}{'source'};
    my $source_ID = shift;
    return error('need a channel source ID as second parameter') unless defined $source_ID;
    return warning("there is no channel named $source_ID ") unless defined $net{$source_ID};
    return warning("source channel $source_ID is an OUT channel") if defined $net{$source_ID}{'source'};
    return warning("OUT channel $channel_ID has no $source_ID as source")
        unless defined $net{$channel_ID}{'source'}{$source_ID};
    delete $net{$source_ID}{'target'}{$channel_ID};
    delete $net{$channel_ID}{'source'}{$source_ID};
}

################################################################################

sub add_target           { # CID TID code --> Hashref(target)/0
    return error('need max. 3 parameter: channel (in type) and target channel (out) or channel (out), target_ID and code') if @_ > 3;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $target_ID, $code) = @_;
    return error('need a channel target ID as second parameter') unless defined $target_ID;
    return warning("channel $channel_ID has already a target named $target_ID")
        if defined $net{$channel_ID}{'target'}{$target_ID};
    if (defined $code){
        return warning('only IN channel have outputs with code') unless defined $net{$channel_ID}{'source'};
        $net{$channel_ID}{'target'}{$target_ID}{'code'} = $code;
        eval '$net{$channel_ID}{"target"}{$target_ID}{"ref"} = sub { $_ = my $msg = shift;'." $code}";
        if ($@){
            delete $net{$channel_ID}{'target'}{$target_ID};
            warning('target code could not be evaluated: '.$@);
            0;
        } else { 1 }
    } else {
        return error('need a code as third parameter') if defined $net{$channel_ID}{'source'};
        add_source($target_ID, $channel_ID);
    }
}

sub get_target           { # CID TID       --> Str(source)/1/0
    return error('need only 2 parameter: channel_ID and target_ID') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $target_ID) = @_;
    return error('need a target ID as second parameter') unless defined $target_ID;
    return 0 unless defined $net{$channel_ID}{'target'}{$target_ID};
    return 1 unless defined $net{$channel_ID}{'source'};
    $net{$channel_ID}{'target'}{$target_ID}{'code'};
}

sub list_targets         { # CID      --> [TID]
    return error('need only 1 parameter: channel_ID') if @_ > 1;
    return unless _approve_channel_ID($_[0]);
    sort keys %{$net{ (shift) }{'target'}};
}

sub remove_target        { # CID TID  --> Hashref(target)
    return error('need only 2 parameter: channel_ID and target_ID') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $target_ID) = @_;
    return error('need a target ID as second parameter') unless defined $target_ID;
    return warning("channel $channel_ID has no target with ID $target_ID")
        unless defined $net{$channel_ID}{'target'}{$target_ID};
    delete $net{$target_ID}{'source'}{$channel_ID} unless defined $net{$channel_ID}{'source'};
    delete $net{$channel_ID}{'target'}{$target_ID};
}

################################################################################
#   channel filter
################################################################################

sub create_filter        { # CID ("source" SID)? kind? FID str/rx --> 1|0      =kind:/map grep!/
    return error('need max. 6, min. 3 parameter: '.
            'channel_ID, ["source", source_ID], [filter kind], filter_ID, code string or regex') if @_ > 6 or @_ < 3;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    my $filter = { code => pop, active => 1};
    if (ref $filter->{'code'} eq 'Regexp'){
        eval '$filter->{"ref"} = sub { my $msg = $_[0]; $msg->{"content"} =~ '." /$filter->{'code'}/ }";
    } else {
        eval '$filter->{"ref"} = sub { my $msg = $_[0];'." $filter->{'code'} }";
    }
    return error('code could not be evaluated '.$@), 0 if $@;
    my $filter_ID = pop;
    if (scalar @_ < 2){
        my $kind = shift // 'grep';
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        return warning("channel channel_ID has already $kind filter named $filter_ID")
            if defined $net{$channel_ID}{'filter'}{$kind}{$filter_ID};
        $net{$channel_ID}{'filter'}{$kind}{$filter_ID} = $filter;
        return 1;
    } else {
        my ($source, $source_ID, $kind) = @_;
        return error('second of 5 or 6 parameters must be literal "source",'.
            ' because new filter applies only to messages from that source') unless $source eq 'source';
        return warning("channel $channel_ID has no sources (only out channel have)") unless defined $net{$channel_ID}{'source'};
        return warning("$source_ID is not a source of channel channel_ID") unless defined $net{$channel_ID}{'source'}{$source_ID};
        $kind = 'grep' unless defined $kind;
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        return warning("channel $channel_ID source $source_ID has already $kind filter with ID $filter_ID")
            if defined $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID};
        $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID} = $filter;
        1;
    }
}

sub get_filter           { # CID ("source" SID)? kind? FID        --> str/rx|0
    return error('need max. 5, min. 2 paramter: channel_ID, ["source", source_ID], [filter kind], filter_ID') if @_ > 5 or @_ < 2;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    my $filter_ID = pop;
    if (scalar @_ < 2){
        my $kind = shift // 'grep';
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        defined $net{$channel_ID}{'filter'}{$kind}{$filter_ID} 
            ? $net{$channel_ID}{'filter'}{$kind}{$filter_ID}{'code'} : 0;
    } else {
        my ($source, $source_ID, $kind) = @_;
        return error('second of 4 or 5 parameters must be "source", because filter applies only to messages from one source')
            unless $source eq 'source';
        $kind = 'grep' unless defined $kind;
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        return 0 unless defined $net{$channel_ID}{'source'};
        return 0 unless defined $net{$channel_ID}{'source'}{$source_ID};
        return 0 unless defined $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID};
        $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID}{'code'};
    }
}

sub list_filter          { # CID ("source" SID)? kind?            --> [FID]
    return error('need max. 4, min. 1 paramter: channel_ID, ["source", source_ID], [filter kind]') if @_ > 4 or @_ < 1;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    if (scalar @_ < 2){
        my $kind = shift // 'grep';
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        sort keys %{ $net{$channel_ID}{'filter'}{$kind} };
    } else {
        my ($source , $source_ID, $kind) = @_;
        return error('second of 3 or 4 parameters must be "source", because filter apply only to messages from one source')
            unless $source eq 'source';
        return warning("channel $channel_ID has no sources (only out channel have)") unless defined $net{$channel_ID}{'source'};
        return warning("$source is not a dource of channel channel_ID ") unless defined $net{$channel_ID}{'source'}{$source_ID};
        $kind = 'grep' unless defined $kind;
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        sort keys %{ $net{$channel_ID}{'source'}{$source_ID}{$kind} };
    }
}

sub switch_filter        { # CID ("source" SID)? kind? FID mode   --> 1|0      =mode:/on! off/
    return error('need max. 6, min. 3 paramter: '.
        'channel_ID, ["source", source_ID], [filter kind], [filter_ID], new filter state') if @_ > 6 or @_ < 3;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    my $mode = pop;
    return error('filter state can only be "on" or "off"') unless $mode eq 'on' or $mode eq 'off';
    $mode = $mode eq 'on' ? 1 : 0;
    my $filter_ID = pop;
    if (scalar @_ < 2){
        my $kind = shift // 'grep';
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        warning("channel $channel_ID has no $kind filter named $filter_ID")
            unless defined $net{$channel_ID}{'filter'}{$kind}{$filter_ID};
        $net{$channel_ID}{'filter'}{$kind}{$filter_ID}{'active'} = $mode;

    } else {
        my ($source, $source_ID, $kind) = @_;
        return error('second of 5 or 6 parameters must be "source", because filter applies only to messages from one source')
            unless $source eq 'source';
        return warning("channel $channel_ID has no sources (only out channel have)") unless defined $net{$channel_ID}{'source'};
        return warning("channel $channel_ID has no source named $source_ID") unless defined $net{$channel_ID}{'source'}{$source_ID};
        $kind = 'grep' unless defined $kind;
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        return warning("channel $channel_ID source $source_ID has no $kind filter with ID $filter_ID")
            unless defined $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID};
        $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID}{'active'} = $mode;
    }
 }

sub filter_active        { # CID ("source" SID)? kind? FID        --> 1|0
    return error('need max. 5, min. 2 paramter: channel_ID, ["source", source_ID], [filter kind], filter_ID') if @_ > 5 or @_ < 2;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    my $filter_ID = pop;
    if (scalar @_ < 2){
        my $kind = shift // 'grep';
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        warning("channel $channel_ID has no $kind filter named $filter_ID")
            unless defined $net{$channel_ID}{'filter'}{$kind}{$filter_ID};
        $net{$channel_ID}{'filter'}{$kind}{$filter_ID}{'active'};
    } else {
        my ($source, $source_ID, $kind) = @_;
        return error('second of 4 or 5 parameters must be "source", because filter applies only to messages from one source')
            unless $source eq 'source';
        $kind = 'grep' unless defined $kind;
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        return unless defined $net{$channel_ID}{'source'};
        return unless defined $net{$channel_ID}{'source'}{$source_ID};
        return unless defined $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID};
        $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID}{'active'};
    }
}

sub delete_filter        { # CID ("source" SID)? kind? FID        --> Hashref(filter)
    return error('need max. 5, min. 2 paramter: channel_ID, ["source", source_ID], [filter kind], filter_ID') if @_ > 5 or @_ < 2;
    return unless _approve_channel_ID($_[0]);
    my $channel_ID = shift;
    my $filter_ID = pop;
    if (scalar @_ < 2){
        my $kind = shift // 'grep';
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        warning("channel $channel_ID has no $kind filter named $filter_ID")
            unless defined $net{$channel_ID}{'filter'}{$kind}{$filter_ID};
        delete $net{$channel_ID}{'filter'}{$kind}{$filter_ID};
    } else {
        my ($source, $source_ID, $kind) = @_;
        return warning("channel $channel_ID has no sources (only out channel have)") unless defined $net{$channel_ID}{'source'};
        return warning("channel $channel_ID has no source named $source_ID") unless defined $net{$channel_ID}{'source'}{$source_ID};
        return error('second of 4 or 5 parameters must be "source", because filter applies only to messages from one source')
            unless $source eq 'source';
        $kind = 'grep' unless defined $kind;
        return error('only kinds of filter are "map" or "grep"') unless $kind eq 'map' or $kind eq 'grep';
        return warning("channel $channel_ID has no sources (only out channel have)") unless defined $net{$channel_ID}{'source'};
        return warning("channel $channel_ID has no source named $source_ID") unless defined $net{$channel_ID}{'source'}{$source_ID};
        return warning("channel $channel_ID source $source_ID has no $kind filter with ID $filter_ID")
            unless defined $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID};
        delete $net{$channel_ID}{'source'}{$source_ID}{$kind}{$filter_ID};
    }
}

################################################################################
#   message
################################################################################

sub send_message         { # CID Str|Hashref --> 1|0
    return error('need 2 paramter: channel_ID and message (String or Hashref)') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $msg) = @_;
    return note("sent message to muted channel ".$channel_ID )
        if $net{$channel_ID}{'mute'} or $global_mute;
    return error('need a message as second parameter') unless defined $msg;
    my $type = channel_type($channel_ID);
    my $n;
    if ($type eq 'in') { # building the message
        $msg = {content => $msg} unless ref $msg eq 'HASH';
        return error('need a message as second parameter') unless $msg->{'content'};
        my @time = (localtime);
        $msg->{'time'} = sprintf "%02u:%02u:%02u:%02u", @time[2,1,0], int((gettimeofday())[1]/10_000);
        $msg->{'date'} = sprintf "%02u.%02u.%u", $time[3], $time[4]+ 1, $time[5]+ 1900;
        my($line, $caller) = (caller(1))[2,3];
        my $pos = rindex($caller, '::');
        my $package = substr($caller, 0, $pos);
        my $sub =    substr($caller, $pos+2);
        if ($package eq 'Kephra::API'){
           ($line, $caller) = (caller(2))[2,3];
            if ($caller){
                $pos = rindex($caller, '::');
                $package = substr($caller, 0, $pos);
                $sub =    substr($caller, $pos+2);
                if (substr($sub,0,1) eq '_'){
                   ($line, $caller) = (caller(3))[2,3];
                    $pos = rindex($caller, '::');
                    $package = substr($caller, 0, $pos);
                    $sub =    substr($caller, $pos+2);
                }
            }
        }
        $msg->{'line'} = $line;
        $msg->{'package'} = $package;
        $msg->{'sub'} = $sub;
    } else { # deep copy of the msg so IN and OUT channel store different msg refs
        $n->{$_} = $msg->{$_} for keys %$msg;
        $msg = $n;
    }
    $msg->{ $type.'_channel' } = $channel_ID;

    # grep filter (rejecting messages)
    if ($type eq 'out' and $msg->{'in_channel'}) {
        for (values %{ $net{$channel_ID}{'source'}{ $msg->{'in_channel'} }{'grep'} }){
            next unless $_->{'active'};
            return note("message filtered from channel $channel_ID") unless $_->{'ref'}->($msg);
        }
    }
    for (values %{ $net{$channel_ID}{'filter'}{'grep'} }){
        next unless $_->{'active'};
        return note("message filtered from channel $channel_ID") unless $_->{'ref'}->($msg);
    }

    # map filter (rewriting content)
    if ($type eq 'out' and $msg->{'in_channel'}) {
        for (sort keys %{ $net{$channel_ID}{'source'}{ $msg->{'in_channel'} }{'map'} }){
            next unless $net{$channel_ID}{'source'}{ $msg->{'in_channel'} }{'map'}{$_}{'active'};
            $msg->{'content'} = $net{$channel_ID}{'source'}{ $msg->{'in_channel'} }{'map'}{$_}{'ref'}->($msg);
        }
    }
    for (sort keys %{ $net{$channel_ID}{'filter'}{'map'} }){
        next unless $net{$channel_ID}{'filter'}{'map'}{$_}{'active'};
        $msg->{'content'} = $net{$channel_ID}{'filter'}{'map'}{$_}{'ref'}->($msg);
    }

    push @{$net{$channel_ID}{'message'}}, $msg;
    _channel_send_msg_to_all_target($channel_ID) unless $net{$channel_ID}{'close'} or $global_close;
    trim_channel($channel_ID, $net{$channel_ID}{'quota'})
        if scalar @{$net{$channel_ID}{'message'}} > $net{$channel_ID}{'quota'};
    $msg;
}

sub get_message          { # CID +|-pos?     --> [msg]|msg
    return error('need max. 2 paramter: channel_ID [and message position]') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $nr) = (@_ );
    if (defined $nr){
        $nr = int $nr;
        my $last_nr = $#{$net{$channel_ID}{'message'}};
        return warning("position of last message is $last_nr in channel $channel_ID") if $last_nr < abs($nr);
        $net{$channel_ID}{'message'}[$nr];
    } else {
        return @{ $net{$channel_ID}{'message'} };
    }
}

sub trim_channel         { # CID int     --> [msg]
    return error('need max. 2 paramter: channel_ID [and amount of messages left, default is 0]') if @_ > 2;
    return unless _approve_channel_ID($_[0]);
    my ($channel_ID, $new_size) = ($_[0], int ($_[1] || 0) );
    my $there = @{$net{$channel_ID}{'message'}};
    return note("nothing to trim on channel $channel_ID") if $new_size < 0 or $there <= $new_size;
    $net{$channel_ID}{'cursor_pos'} -= $there - $new_size;
    $net{$channel_ID}{'cursor_pos'} = 0 if $net{$channel_ID}{'cursor_pos'} < 0;
    splice @{$net{$channel_ID}{'message'}}, 0, $there - $new_size;
}

################################################################################
#   AUX
################################################################################

sub _approve_channel_ID {
    return error('need a channel ID as fist parameter') unless (defined $_[0]);
    return warning("no channel $_[0] exists") unless defined $net{$_[0]};
    return 1;
}

sub _channel_send_msg_to_all_target {
    my $CID = shift; # channel ID
    my $type = channel_type($CID);
    my $there = @{$net{$CID}{'message'}};
    while (($net{$CID}{'cursor_pos'} + $net{$CID}{'package_size'}) <= $there){
        if ($type eq 'in'){
            for my $target_ID (keys %{$net{$CID}{'target'}}){
                send_message($target_ID, $net{$CID}{'message'}[ $net{$CID}{'cursor_pos'} + $_ ])
                    for 0 .. $net{$CID}{'package_size'} - 1;
            }
        } else {
            for my $target (values %{$net{$CID}{'target'}}){

                $target->{'ref'}( $net{$CID}{'message'}[ $net{$CID}{'cursor_pos'} + $_ ] )
                    for 0 .. $net{$CID}{'package_size'} - 1;
            }
        }
        $net{$CID}{'cursor_pos'} += $net{$CID}{'package_size'};
    }
}

sub report_status        { # msg status to report channel
    return error('need no parameter') if @_ > 0;
    my $r = __PACKAGE__. ":\n";
    for my $channel_ID (list_channel()){
        $r .= "  channel : $channel_ID\n";
        $r .= '    type     :'.channel_type($channel_ID)."\n";
        $r .= '    state    :'.channel_state($channel_ID)."\n";
        $r .= "    quota    : $net{$channel_ID}{'quota'}\n";
        $r .= "    pkg size : $net{$channel_ID}{'package_size'}\n";
        $r .= "    filter :\n";
        for my $type (qw/grep map/){
            $r .= "      $type :\n";
            for my $filter_ID (keys %{ $net{$channel_ID}{'filter'}{$type} }){
                $r .= "        $filter_ID : ";
                $r .= $net{$channel_ID}{'filter'}{$type}{$filter_ID}{'active'} ? 'active' : 'inactive';
                $r .= ':'.$net{$channel_ID}{'filter'}{$type}{$filter_ID}{'code'}."\n";
            }
        }
        if (defined $net{$channel_ID}{'source'}) {
            $r .= '    sources :'."\n";
            for my $source_ID (keys %{$net{$channel_ID}{'source'}}){
                $r .= "      $source_ID :\n";
                for my $type (qw/grep map/){
                    $r .= "        $type :\n";
                    for my $filter_ID (keys %{$net{$channel_ID}{'source'}{$source_ID}{$type}}){
                        $r .= "          $filter_ID : ";
                        $r .= $net{$channel_ID}{'source'}{$source_ID}{$type}{$filter_ID}{'active'} ? 'active' : 'inactive';
                        $r .= ':'.$net{$channel_ID}{'source'}{$source_ID}{$type}{$filter_ID}{'code'}."\n";
                    }
                }
            }
            $r .= '    targets :'."\n";
            $r .= "      $_ : $net{$channel_ID}{'target'}{$_}{'code'}\n" for keys %{$net{$channel_ID}{'target'}};
        } else {
            $r .= "    targets :\n";
            $r .= "      channel $_\n" for keys %{$net{$channel_ID}{'target'}};
        }
        $r .= "    messages   : ".(scalar @{$net{$channel_ID}{'message'}})."\n";
        $r .= "    cursor pos : $net{$channel_ID}{'cursor_pos'}\n";
   }
   report($r);
}

################################################################################
1;
