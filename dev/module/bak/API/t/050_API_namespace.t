#!/usr/bin/perl -w
use v5.14;
no warnings;
no strict;
# use warnings;
use Test::More tests => 28;

BEGIN { unshift @INC, 'lib', '../lib'}


use_ok( 'Kephra::API' );
can_ok( 'Kephra::API', $_) for qw/app app_window doc_panel doc_bar all_doc_bar document all_documents editor
                                  error warning note report date_time sub_caller create_counter
                                  is_int is_uc is_object is_call is_widget is_editor is_document is_tab_bar is_panel is_sizer is_color is_font/;


exit 0;
