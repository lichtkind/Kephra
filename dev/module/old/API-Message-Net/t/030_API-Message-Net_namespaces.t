#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 47;

BEGIN { unshift @INC, 'lib', '../lib'}

use_ok( 'Kephra::API::Message' );
can_ok( 'Kephra::API::Message', $_) for qw/set_channel content topic date time sender channel_in channel_out/;

use_ok( 'Kephra::API::Message::Channel' );
can_ok( 'Kephra::API::Message::Channel', $_) for qw/new name type get_state set_state get_size set_size
                                                    add_filter get_filter_IDs get_filter remove_filter 
                                                    add_target get_target_IDs get_target remove_target 
                                                    append_message message_count remove_messages status/;

use_ok( 'Kephra::API::Message::Net' );
can_ok( 'Kephra::API::Message::Net', $_) for qw/new get_state set_state 
                                                create_channel get_channel_names get_channel delete_channel 
                                                connect_channel disconnect_channel get_connected_channel send_message status/;

use_ok( 'Kephra::API' );
can_ok( 'Kephra::API', $_) for qw/error warning note report/;


exit 0;
