#!/usr/bin/perl -w
#                      DO NOT MOOVE CODE -- LINE NR ARE PART OF SOME TESTS !!!
use v5.14;
use warnings;
use Test::More tests => 156;

BEGIN { unshift @INC, 'lib', '../lib'}
use Kephra::API::Message::Net;

my (@warning, @error, @note, @report, @cnr);
our @good;
my ($OCID, $ICID) = (qw/good in/); # channel ID (OUT), IN channel ID

no strict 'refs';
no warnings;
*{'Kephra::API::Message::Net::error'}   = sub {push @error, shift };
*{'Kephra::API::Message::Net::warning'} = sub {push @warning, shift };
*{'Kephra::API::Message::Net::note'}    = sub {push @note, shift };
*{'Kephra::API::Message::Net::report'}  = sub {push @report, shift };
sub TestPackage::send_msg { Kephra::API::Message::Net::send_message(@_) } # simulate call from another package
use strict 'refs';
use warnings;

# global reset
Kephra::API::Message::Net::delete_channel($_) for Kephra::API::Message::Net::list_channel();

# create delete channel
is( (@cnr = Kephra::API::Message::Net::list_channel()),       0, 'start with empty channel list');
is( Kephra::API::Message::Net::has_channel($OCID),            0, 'start with no channel');
is( Kephra::API::Message::Net::create_channel($OCID),         1, 'got confirmation that channel was created');
is( Kephra::API::Message::Net::has_channel($OCID),            1, 'created channel recognized');
is( scalar (@cnr = Kephra::API::Message::Net::list_channel()),1, 'one channel can be listed');
is( (Kephra::API::Message::Net::list_channel())[0], $OCID      , 'right channel can be listed');
is( ref Kephra::API::Message::Net::delete_channel($OCID),'HASH','deleted channel was a hashref');
is( Kephra::API::Message::Net::has_channel($OCID),            0, 'deleted channel can not be recognized');
is( (@cnr = Kephra::API::Message::Net::list_channel()),       0, 'zero channels exist again');
Kephra::API::Message::Net::create_channel();
like( pop(@error),qr/need a channel ID as fist parameter/    , 'need a channel ID to create a channel');
Kephra::API::Message::Net::create_channel($OCID, 'out', 500, 5, 'open');
Kephra::API::Message::Net::create_channel($OCID);
like( pop(@warning) ,                qr/already exists/      , 'can\'t create two channel with same ID');
Kephra::API::Message::Net::delete_channel();
like( pop(@error),qr/need a channel ID as fist parameter/    , 'delete channel needs an channel ID');
Kephra::API::Message::Net::delete_channel($OCID.$ICID);
like( pop(@warning),                     qr/no channel/      , 'can\'t delete none existing channel');

# channel properties
is( Kephra::API::Message::Net::channel_type($OCID),       'out', 'right channel type out');
Kephra::API::Message::Net::create_channel($ICID, 'in');
is( Kephra::API::Message::Net::channel_type('in'),         'in', 'right channel type in');
@cnr = Kephra::API::Message::Net::list_channel();
is( scalar @cnr,                                            2, 'now we have two channel');
is( join( '', sort @cnr), join( '', sort $OCID,$ICID)        , 'correct two channel names');

is( Kephra::API::Message::Net::channel_quota($OCID),        500, 'right quota type');
Kephra::API::Message::Net::channel_quota($OCID, 1000);
is( Kephra::API::Message::Net::channel_quota($OCID),       1000, 'right quota again');

is( Kephra::API::Message::Net::package_size($OCID),           5, 'right package size');
Kephra::API::Message::Net::package_size($OCID, 2);
is( Kephra::API::Message::Net::package_size($OCID),           2, 'right package size');

is( Kephra::API::Message::Net::channel_state($OCID),     'open','channel state is open');
Kephra::API::Message::Net::channel_state($OCID, 'close');
is( Kephra::API::Message::Net::channel_state($OCID),    'close','channel state is close');
Kephra::API::Message::Net::channel_state($OCID, 'mute');
is( Kephra::API::Message::Net::channel_state($OCID),     'mute', 'channel state is mute');
Kephra::API::Message::Net::channel_state($OCID, 'open');

# channel sources
Kephra::API::Message::Net::list_sources($ICID);
like( pop(@warning),     qr/is not an OUT channel/           , 'can\'t list IN channel sources');
@cnr = Kephra::API::Message::Net::list_targets($ICID);
is( scalar @cnr,                                            0, 'no sourse yet for default IN channel');
@cnr = Kephra::API::Message::Net::list_sources($OCID);
is( scalar @cnr,                                            0, 'no sourse yet for default OUT channel');
is( Kephra::API::Message::Net::add_source($OCID, $ICID),      1, 'created source is a hashref');
@cnr = Kephra::API::Message::Net::list_sources($OCID);
is( scalar @cnr,                                            1, 'added one source');
@cnr = Kephra::API::Message::Net::list_targets($ICID);
is( scalar @cnr,                                            1, '.. and target in source channel');
is( (Kephra::API::Message::Net::list_sources($OCID))[0],  $ICID, 'right channel source can be listed');
is(  Kephra::API::Message::Net::has_source($OCID,$ICID),      1, 'first source detected');
is(  Kephra::API::Message::Net::has_source($OCID,$OCID),      0, 'OUT channel cant have itself as source');
is( ref Kephra::API::Message::Net::remove_source($OCID,  $ICID), 'HASH', 'removed channel source was a hashref');
is(  Kephra::API::Message::Net::has_source($OCID,$ICID),      0, 'source was removed');
@cnr = Kephra::API::Message::Net::list_sources($OCID);
is( scalar @cnr,                                            0, 'no sourse left');
@cnr = Kephra::API::Message::Net::list_targets($ICID); 
is( scalar @cnr,                                            0, 'and no targets on source channel');
Kephra::API::Message::Net::add_source($OCID, $ICID);
Kephra::API::Message::Net::add_source($OCID, $ICID);
like( pop(@warning) , qr/has already/, 'can\'t create source twice');

# channel targets
is( Kephra::API::Message::Net::get_target($ICID, $OCID),      1, 'one channels source is anothers target');
is( ref Kephra::API::Message::Net::remove_target($ICID,  $OCID), 'HASH', 'removed channel target was a hashref');
@cnr = Kephra::API::Message::Net::list_targets($ICID);
is( scalar @cnr,                                            0, 'IN channels target deleted');
@cnr = Kephra::API::Message::Net::list_sources($OCID);
is( scalar @cnr,                                            0, 'and OUT channels source was deleted too');
is( Kephra::API::Message::Net::has_source($OCID,$ICID),       0, 'so source ID of OUT is no longer there');
is( Kephra::API::Message::Net::get_target($ICID,$OCID),       0, 'so target ID of IN is no longer there');
is( Kephra::API::Message::Net::add_target($ICID,$OCID),       1, 'created target is a hashref');
is( Kephra::API::Message::Net::get_target($ICID,$OCID),       1, 'target of IN channel was created');
is( Kephra::API::Message::Net::has_source($OCID,$ICID),       1, 'source of OUT channel was created');
@cnr = Kephra::API::Message::Net::list_sources($OCID);
is( scalar @cnr,                                            1, 'added one source');
@cnr = Kephra::API::Message::Net::list_targets($ICID);
is( scalar @cnr,                                            1, '.. and target in source channel');

my ($target,$tcode) = ('t0', 'push @main::good, $msg');
@cnr = Kephra::API::Message::Net::list_targets($OCID);
is( scalar @cnr,                                            0, 'no targets on default OUT channel');
is(  Kephra::API::Message::Net::get_target($OCID, $target),   0, 'target not yet created');
Kephra::API::Message::Net::add_target($OCID, $target, $tcode);
@cnr = Kephra::API::Message::Net::list_targets($OCID);
is( scalar @cnr,                                            1, 'target of OUT channel was created');
is( $cnr[0],                                          $target, 'right channel target can be listed');
is( Kephra::API::Message::Net::get_target($OCID, $target), $tcode,'target got right code');
is( Kephra::API::Message::Net::get_target($OCID,$target.$OCID),0,'this target should not be there');
Kephra::API::Message::Net::remove_target($OCID, $target);
@cnr = Kephra::API::Message::Net::list_targets($OCID);
is( scalar @cnr,                                             0, 'OUT channel target was deleted');
is(  Kephra::API::Message::Net::get_target($OCID, $target),    0, 'target ID of OUT channel is gone');
Kephra::API::Message::Net::add_target($OCID, $target, $tcode);

# create delete filter
my ($mfilter, $gfilter, $mcode, $gcode) = ('f0', 'f1', '$msg->{"in_channel"}', qr/j/);
@cnr = Kephra::API::Message::Net::list_filter($OCID);
is( scalar @cnr,                                              0, 'no filter yet');
is(  Kephra::API::Message::Net::get_filter($OCID, $gfilter),    0, 'specific filter not yet there');
is( Kephra::API::Message::Net::create_filter($OCID, 'grep', $gfilter, $gcode), 1, 'created filter is a hashref');
@cnr = Kephra::API::Message::Net::list_filter($OCID);
is( scalar @cnr,                                              1, 'filter created');
is(  Kephra::API::Message::Net::get_filter($OCID, $gfilter),$gcode,'specific filter created');
is(  Kephra::API::Message::Net::get_filter($OCID, $OCID),       0, 'and no other filter created');
is( ref Kephra::API::Message::Net::delete_filter($OCID, 'grep', $gfilter), 'HASH', 'deleted filter was a hashref');
@cnr = Kephra::API::Message::Net::list_filter($OCID, 'grep');
is( scalar @cnr,                                              0, 'no filter in list again');
is(  Kephra::API::Message::Net::get_filter($OCID, $gfilter),    0, 'specific filter not there again');
@cnr = Kephra::API::Message::Net::list_filter($OCID, 'source', $ICID, 'map');
is( scalar @cnr,                                              0, 'no source filter in list yet');
is(  Kephra::API::Message::Net::get_filter($OCID, 'source', $ICID, 'map', $mfilter), 0,'specific source filter not yet created');
Kephra::API::Message::Net::create_filter($OCID, 'grep', $gfilter, $gcode);
is( Kephra::API::Message::Net::create_filter($OCID, 'source', $ICID, 'map', $mfilter, $mcode), 1, 'created source filter is a hashref');
@cnr = Kephra::API::Message::Net::list_filter($OCID, 'source', $ICID, 'map' );
is( scalar @cnr,                                              1, 'created source filter is in list');
is(  Kephra::API::Message::Net::get_filter($OCID, 'source', $ICID, 'map', $mfilter),$mcode,'specific source filter created');
my $hashref = Kephra::API::Message::Net::delete_filter($OCID, 'source', $ICID, 'map', $mfilter);
is( ref $hashref,                                        'HASH', 'deleted source filter was a hashref');
@cnr = Kephra::API::Message::Net::list_filter($OCID, 'source', $ICID, 'map');
is( scalar @cnr,                                              0, 'no source filter after one was deleted');
is(  Kephra::API::Message::Net::get_filter($OCID, 'source', $ICID, 'map', $mfilter), 0,'specific source filter not there again');
Kephra::API::Message::Net::create_filter($OCID, 'source', $ICID, 'map', $mfilter, $mcode);

# switching filter on and off
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 1, 'our grep filter is active');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 1, 'source filter is active');

Kephra::API::Message::Net::switch_filter($OCID, 'grep', $gfilter, 'off');
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 0, 'our grep filter was turned off');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 1, 'source filter untouched by local filter switch');
Kephra::API::Message::Net::switch_filter($OCID, 'grep', $gfilter, 'on');
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 1, 'our grep filter was turned on');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 1, 'source filter untouched by local filter switch');
Kephra::API::Message::Net::switch_filter($OCID, 'grep',$_, 'off')
    for Kephra::API::Message::Net::list_filter($OCID, 'grep');
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 0, 'all grep filter was turned off, so our particular too');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 1, 'source filter untouched by local filter switch');
Kephra::API::Message::Net::switch_filter($OCID, 'grep',$_, 'on')
    for Kephra::API::Message::Net::list_filter($OCID, 'grep');
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 1, 'all grep filter was turned on, so our particular too');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 1, 'source filter untouched by local filter switch');

Kephra::API::Message::Net::switch_filter($OCID, 'source', $ICID, 'map', $mfilter, 'off');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 0, 'source filter was turned off');
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 1, 'our grep filter untouched');
Kephra::API::Message::Net::switch_filter($OCID, 'source', $ICID, 'map', $mfilter, 'on');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 1, 'source filter was turned on');
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 1, 'our grep filter untouched');
Kephra::API::Message::Net::switch_filter($OCID, 'map', $ICID, 'source', 'off');
Kephra::API::Message::Net::switch_filter($OCID, 'source', $ICID, 'map', $_, 'off')
    for Kephra::API::Message::Net::list_filter($OCID, 'source', $ICID, 'map');
is(  Kephra::API::Message::Net::filter_active($OCID, 'source', $ICID, 'map', $mfilter), 0, 'map source filter bulk was turned off, so our source filter too');
is(  Kephra::API::Message::Net::filter_active($OCID, 'grep', $gfilter), 1, 'our grep filter untouched');
Kephra::API::Message::Net::switch_filter($OCID, 'grep',$_, 'off')
    for Kephra::API::Message::Net::list_filter($OCID, 'grep');

# sending  messages
my ($ahoaj, $jou) = (qw/ahoaj jou/);
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              0, 'no message yet in IN channel');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              0, 'no message yet in OUT channel');
Kephra::API::Message::Net::get_message($ICID,0);
like( pop(@warning) ,                      qr/position of last/, 'there is not even a message number zero in IN');
Kephra::API::Message::Net::get_message($OCID,0);
like( pop(@warning) ,                      qr/position of last/, 'there is not even a message number zero in OUT');
Kephra::API::Message::Net::channel_state($ICID, 'mute');
Kephra::API::Message::Net::channel_state($OCID, 'mute');
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              0, 'IN channel successfully muted');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              0, 'OUT channel successfully muted');
Kephra::API::Message::Net::channel_state($ICID, 'close');
Kephra::API::Message::Net::channel_state($OCID, 'close');
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($OCID, {content => $ahoaj});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              1, 'IN channel recieved one piece of something');
@cnr = Kephra::API::Message::Net::get_message($ICID, 0);
is( ref $cnr[0]                                         ,'HASH', 'could be a message in IN');
is( $cnr[0]->{'content'},                                $ahoaj, 'it seems to be out mesage in IN');
is( $cnr[0]->{'in_channel'},                              $ICID, 'channel ID of IN channel was tracked correctly');
is( $cnr[0]->{'package'},                         'TestPackage', 'caller package of IN channel message was tracked correctly');
is( $cnr[0]->{'line'},                                      208, 'code line of caller sub routine of IN channel message was tracked correctly');
is( $cnr[0]->{'sub'},                                'send_msg', 'caller sub routine of IN channel message was tracked correctly');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              1, 'OUT channel recieved one piece of something');
@cnr = Kephra::API::Message::Net::get_message($OCID, 0);
is( ref $cnr[0]                                         ,'HASH', 'could be a message in OUT');
is( $cnr[0]->{'content'},                                $ahoaj, 'it seems to be out mesage in OUT');
is( $cnr[0]->{'out_channel'},                             $OCID, 'channel ID of OUT channel was tracked correctly');
Kephra::API::Message::Net::get_message($ICID, 1);
like( pop(@warning) ,                     qr/position of last/, 'there is not a second message in IN channel');
Kephra::API::Message::Net::get_message($OCID, 1);
like( pop(@warning) ,                     qr/position of last/, 'there is not a second message in OUT channel');
Kephra::API::Message::Net::trim_channel($ICID);
Kephra::API::Message::Net::trim_channel($OCID,0);
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              0, 'IN channel successfully trimmed (emptied)');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              0, 'OUT channel successfully trimmed (emptied)');
Kephra::API::Message::Net::channel_state($ICID, 'open');
TestPackage::send_msg($ICID, $ahoaj);
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              1, 'sent message was stored in IN channel');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              1, 'sent message was forewarded to OUT channel');
is( scalar @good,                                             0, 'final output is yet empty');
Kephra::API::Message::Net::channel_state($OCID, 'open');
TestPackage::send_msg($ICID, $jou);
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              2, 'sent message was stored in IN channel');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              2, 'sent message was forewarded to OUT channel');
is( scalar @good,                                             2, 'both message plopped out of the final output'); # package size was 2
Kephra::API::Message::Net::trim_channel($ICID);                  #  empty all pockets
Kephra::API::Message::Net::trim_channel($OCID);
@good = ();

# using grep filter
my ($ggfilter, $ggcode) = ('f3', '$msg->{"content"} =~ /h/');
Kephra::API::Message::Net::delete_filter($OCID, 'grep', $gfilter,);
Kephra::API::Message::Net::delete_filter($OCID, 'source', $ICID, 'map', $mfilter);
Kephra::API::Message::Net::create_filter($ICID, 'grep', $ggfilter, $ggcode);
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($ICID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              1, "new $ggfilter filter filtered one of two messages");
is( $cnr[0]->{'content'},                                $ahoaj, 'filtered the right message away');
like( pop(@note) ,                            qr/filtered from/, 'filtering was noted');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              1, 'message also went into OUT channel');
Kephra::API::Message::Net::switch_filter($ICID, 'grep', $ggfilter, 'off');
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($ICID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              3, "could switch off in channel filter successfully");
Kephra::API::Message::Net::create_filter($OCID, 'grep', $gfilter, $gcode);
Kephra::API::Message::Net::trim_channel($ICID);
Kephra::API::Message::Net::trim_channel($OCID);
@good = ();
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($ICID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              2, 'without filter both messages went into IN channel');
is( scalar @good,                                             2, 'both messages passed through filter into OUT channel');
Kephra::API::Message::Net::create_filter($ICID, 'map', $mfilter, $mcode); 
Kephra::API::Message::Net::trim_channel($ICID);
Kephra::API::Message::Net::trim_channel($OCID);
@good = ();
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($ICID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              2, 'both rewritten messages went into IN channel');
is( $cnr[0]->{'content'},                                 $ICID, 'map filter did rewrite message in IN channel');
is( $cnr[1]->{'content'},                                 $ICID, 'map filter did rewrite second message too');
is( scalar @good,                                             0, 'rewritten messages didnt pass into OUT channel');
Kephra::API::Message::Net::delete_filter($ICID, 'map', $mfilter);
Kephra::API::Message::Net::create_filter($OCID, 'source', $ICID, 'map', $mfilter, $mcode);
Kephra::API::Message::Net::trim_channel($ICID);
Kephra::API::Message::Net::trim_channel($OCID);
@good = ();
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($ICID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              2, 'both messages went into IN channel');
is( $cnr[0]->{'content'},                                 $ahoaj,'messages were not rewritten in IN channel (no more map filter there)');
is( scalar @good,                                             2, 'messages landed also in final output');
is( $good[1]->{'content'},                                $ICID, 'messages in OUT channel were rewritten');
@good = ();

# global state
Kephra::API::Message::Net::state('shutdown');
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              0, 'global shut down empties all channels (IN)');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              0, 'global shut down empties all channels (OUT)');
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($OCID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              0, 'can not sen messages after global shut down (IN)');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              0, 'can not sen messages after global shut down (OUT)');
Kephra::API::Message::Net::state('mute');
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($OCID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              0, 'can not send messages after global mute (IN)');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              0, 'can not send messages after global mute (OUT)');
Kephra::API::Message::Net::state('close');
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($OCID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              1, 'can only recieve not send messages after global close (IN)');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              1, 'can only recieve not send messages after global close (OUT)');
is( scalar @good,                                             0, 'no messages land in final output on global close');
Kephra::API::Message::Net::state('open');
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              1, 'messages get flushed after global open (IN)');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              2, 'messages get flushed after global open (OUT)');
is( scalar @good,                                             2, 'messages get flushed after global open (output)');


Kephra::API::Message::Net::trim_channel($ICID);
Kephra::API::Message::Net::trim_channel($OCID);
@good = ();
TestPackage::send_msg($ICID, $ahoaj);
TestPackage::send_msg($OCID, {content => $jou});
@cnr = Kephra::API::Message::Net::get_message($ICID);
is( scalar @cnr,                                              1, 'can recieve and send messages again on global open (IN)');
@cnr = Kephra::API::Message::Net::get_message($OCID);
is( scalar @cnr,                                              2, 'can recieve and send messages again on global open (OUT)');
is( scalar @good,                                             2, 'all messages land in final output on global open');


# self report
Kephra::API::Message::Net::report_status();
my $report = pop(@report);
like( $report ,                                      qr/$ICID/, 'IN channel is in the report');
like( $report ,                                      qr/$OCID/, 'OUT channel is in the report');
like( $report ,                                    qr/$target/, 'the OUT channel target is in the target');
like( $report ,                                   qr/$mfilter/, 'map filter is in the report');
ok( index($report,$mcode) > -1                                , 'map filter code is in the report');
like( $report ,                                   qr/$gfilter/, 'grep filter is in the report');
like( $report ,                                     qr/$gcode/, 'grep filter code is in the report');
like( $report ,                                  qr/$ggfilter/, 'source grep filter is in the report');
ok( index($report,$ggcode) > -1                               , 'source grep filter code is in the report');

exit 0;
