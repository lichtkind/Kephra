#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 46;

BEGIN { unshift @INC, 'lib', '../lib'}

use_ok( 'Kephra::API' );
can_ok( 'Kephra::API', $_) for qw/is_object is_call is_dynacall/;

use_ok( 'Kephra::API::Call' );
can_ok( 'Kephra::API::Call', $_) for qw/new name source is_active set_active run status/;

use_ok( 'Kephra::API::Call::Template' );
can_ok( 'Kephra::API::Call::Template', $_) for qw/new name source_part_left source_part_right is_active set_active new_call new_template status/;

use_ok( 'Kephra::API::Call::Dynamic' );
can_ok( 'Kephra::API::Call::Dynamic', $_) for qw/new name ref_type source is_active set_active get_reference set_reference run status/;

use_ok( 'Kephra::API::Call::Dynamic::Template' );
can_ok( 'Kephra::API::Call::Dynamic::Template', $_) for qw/new new_dynatemplate new_dynacall get_reference set_reference
                                                           name ref_type source_part_left source_part_right is_active set_active status/;


exit 0;
