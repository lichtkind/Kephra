#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 39;

BEGIN { unshift @INC, 'lib', '../lib'}

package API::Test;
use Kephra::API qw/:log/;
our @say;

main::is( Kephra::API::Message::Net::has_channel('say'),       1, 'the default output channel exists');

# preparing output channel so it doesn't go to command line but in msg stack
Kephra::API::Message::Net::remove_target('say', 'say');
Kephra::API::Message::Net::add_target('say', 'say', 'push @API::Test::say, $msg');

test_logging();
test_msgnet_logging();

#error warning note report
sub test_logging {
    @say = ();
    error('error');
    warning('warning');
    note('note');
    report('report');
    main::is( scalar @say,                                 4, 'got four messages from four logging commands');
    main::is( $say[0]->{'content'},                  'error', 'error arrived in final output');
    main::is( $say[1]->{'content'},                'warning', 'warning arrived in final output');
    main::is( $say[2]->{'content'},                   'note', 'warning arrived in final output');
    main::is( $say[3]->{'content'},                 'report', 'warning arrived in final output');
    main::is( $say[0]->{'in_channel'},               'error', 'error message came through error IN channel');
    main::is( $say[1]->{'in_channel'},             'warning', 'warning message came through warning IN channel');
    main::is( $say[2]->{'in_channel'},                'note', 'note message came through note IN channel');
    main::is( $say[3]->{'in_channel'},              'report', 'report message came through report IN channel');
    main::is( $say[0]->{'out_channel'},                'say', 'error message went further through say OUT channel');
    main::is( $say[0]->{'out_channel'},                'say', 'warning message went further through say OUT channel');
    main::is( $say[1]->{'out_channel'},                'say', 'note message went further through say OUT channel');
    main::is( $say[2]->{'out_channel'},                'say', 'report message went further through say OUT channel');
    main::is( $say[3]->{'out_channel'},                'say', 'message went further through say OUT channel');
    main::is( $say[0]->{'package'},              'API::Test', 'caller package of error message was tracked correctly');
    main::is( $say[1]->{'package'},              'API::Test', 'caller package of warning message was tracked correctly');
    main::is( $say[2]->{'package'},              'API::Test', 'caller package of note message was tracked correctly');
    main::is( $say[3]->{'package'},              'API::Test', 'caller package of report message was tracked correctly');
    main::is( $say[0]->{'line'},                          18, 'calling code line for error message was tracked correctly');
    main::is( $say[1]->{'line'},                          18, 'calling code line for warning message was tracked correctly');
    main::is( $say[2]->{'line'},                          18, 'calling code line for note message was tracked correctly');
    main::is( $say[3]->{'line'},                          18, 'calling code line for report message was tracked correctly');
    main::is( $say[0]->{'sub'},               'test_logging', 'identified error caller sub');
    main::is( $say[1]->{'sub'},               'test_logging', 'identified warning caller sub');
    main::is( $say[2]->{'sub'},               'test_logging', 'identified note caller sub');
    main::is( $say[3]->{'sub'},               'test_logging', 'identified report caller sub');
}

sub test_msgnet_logging {
    @say = ();
    Kephra::API::Message::Net::delete_channel();
    Kephra::API::Message::Net::delete_channel('inexistent_channel_ID');
    Kephra::API::Message::Net::remove_target('say');
    Kephra::API::Message::Net::remove_target('say', 'inexistent_target');
    main::like( $say[0]->{'content'}, qr/need a channel ID/,  'error for missing channel ID arrived');
    main::like( $say[1]->{'content'}, qr/no channel/,         'warning for none existing channel ID');
    main::like( $say[2]->{'content'}, qr/need a target ID/,   'error for missing target ID arrived');
    main::like( $say[3]->{'content'}, qr/has no target with /,'warning for none existing channel ID');
    main::is( $say[0]->{'package'},'Kephra::API::Message::Net', 'caller package of error from delete channel recognized');
    main::is( $say[1]->{'package'},'Kephra::API::Message::Net', 'caller package of warning from delete channel recognized');
    main::is( $say[2]->{'package'},'Kephra::API::Message::Net', 'caller package of error from remove target recognized');
    main::is( $say[3]->{'package'},'Kephra::API::Message::Net', 'caller package of warning from remove target recognized');
    main::is( $say[0]->{'sub'},             'delete_channel', 'calling code line of error from delete channel recognized'); # ignores sub name that start with _
    main::is( $say[1]->{'sub'},             'delete_channel', 'calling code line of warning from delete channel recognized'); # ignores sub name that start with _
    main::is( $say[2]->{'sub'},              'remove_target', 'calling code line of error from remove target recognized');
    main::is( $say[3]->{'sub'},              'remove_target', 'calling code line of warning from remove target recognized');
    
}

exit 0;
