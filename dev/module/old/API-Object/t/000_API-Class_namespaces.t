#!/usr/bin/perl -w
use v5.16;
use warnings;
use Test::More tests => 35;

BEGIN { unshift @INC, 'lib', '../lib'}


use_ok( 'Kephra::API::Data' );
can_ok( 'Kephra::API::Data', $_) for qw/clone_item clone_list/;

use_ok( 'Kephra::API::Data::Type' );
can_ok( 'Kephra::API::Data::Type', $_) for qw/verify get_ref_type get_data_type
                                            is_bool is_num is_pos_num is_int is_pos_int is_uc_string is_lc_string 
                                            is_object is_call is_dynacall is_template is_dynatemplate
                                            is_widget is_panel is_sizer is_color is_font/;

use_ok( 'Kephra::API::Package' );
can_ok( 'Kephra::API::Package', $_)    for qw/count_sub has_sub call_sub package_loaded/;

use_ok( 'Kephra::API::Object' );
can_ok( 'Kephra::API::Object', $_)     for qw/new clone/;

use_ok( 'Kephra::API::Class' );
can_ok( 'Kephra::API::Class', $_)      for qw/attribute/;

use_ok( 'Kephra::API::Class::Attribute' );

exit 0;
