#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 46;

BEGIN { unshift @INC, 'lib', '../lib'}

use_ok( 'Kephra::API::Object::Hook' );
can_ok( 'Kephra::API::Object::Hook', $_)  for qw/add_before add_after remove_before remove_after
                                                 get_methods get_before_IDs get_after_IDs get_before get_after/;


use_ok( 'Kephra::API::Object::Queue' );
can_ok( 'Kephra::API::Object::Queue', $_) for qw/new     is_front_closed close_front is_back_closed close_back
                                                 get_min_quota set_min_quota get_max_quota set_max_quota  
                                                 append_item prepend_item remove_front remove_item 
                                                 get_item item_position item_count item_class    status/;
use_ok( 'Kephra::API::Object::Store' );
can_ok( 'Kephra::API::Object::Store', $_) for qw/new  new_item add_item remove_item   
                                                 use_item get_latest_item has_history
                                                 item_class delegate_method  get_ID_by_item get_item_IDs get_item_by_ID 
                                                 item_attributes get_attribute_values get_item_by_atttibute      status/;

exit 0;
