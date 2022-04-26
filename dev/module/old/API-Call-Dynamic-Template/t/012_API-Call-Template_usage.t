#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 63;

BEGIN { unshift @INC, 'lib', '../lib'}
use Kephra::API::Call::Template;

my (@warning, @error, @note, @report);
my ($class, $call_class, $tname, $cname) = ('Kephra::API::Call::Template', 'Kephra::API::Call', 'template', 'call');
no strict 'refs';
no warnings;
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
*{$call_class.'::error'}   = sub { undef; };
*{$call_class.'::warning'} = sub { undef; };
*{$call_class.'::note'}    = sub { undef; };
*{$call_class.'::report'}  = sub { undef; };
use strict 'refs';
use warnings;

# simple getter, defaults, templates get more and  more complex
my ($temp_source_l, $temp_source_r) = ('no warnings "void"; my $d = shift;', '$d - 1;');
my ($call_src_l, $call_src_r) = ('$d *= 2;', '1');
my $temp = Kephra::API::Call::Template->new($tname, $temp_source_l);
is( ref $temp,        'Kephra::API::Call::Template',  'one sided templated created');
is( $temp->name(),                         $tname,  'got template name');
is( $temp->is_active(),                         1,  'templates create on default active calls');
is( $temp->set_active(0),                       0,  'changes activity state');
is( $temp->is_active(),                         0,  'changed state successfully');
is( $temp->set_active(1),                       1,  'changes activity state back');
is( $temp->is_active(),                         1,  'and were on active again');
is( $temp->source_part_left(),     $temp_source_l,  'got left part of source');
is( $temp->source_part_right(),                '',  'got right part of source');

my $call = $temp->new_call($cname, $call_src_l);
is( ref $call, 'Kephra::API::Call', 'call created with one sided source');
is( $call->run(5),              10, 'got result right');
is( $call->run(0),               0, 'got result right again');
is( $call->source(), $temp_source_l.$call_src_l, 'got right source code back');

$call = $temp->new_call($cname, $call_src_l,$call_src_r);
is( ref $call, 'Kephra::API::Call', 'call created with two sided source');
is( ($temp->name()),        $tname, 'got template name');
is( $call->run(5),               1, 'got result right');
is( $call->run(0),               1, 'got result right again');
is( $call->source(), $temp_source_l.$call_src_l.$call_src_r, 'got right source code back');

$temp = Kephra::API::Call::Template->new($tname, $temp_source_l, $temp_source_r);
is( ref $temp,                          $class,  'two sided templated created');
is( $temp->source_part_left(),  $temp_source_l, 'got left source part');
is( $temp->source_part_right(), $temp_source_r, 'got right source part');

$call = $temp->new_call($cname, $call_src_l);
is( ref $call, 'Kephra::API::Call', 'call created with one sided source');
is( $call->run(5),               9, 'got result right');
is( $call->run(0),              -1, 'got result right again');
is( $call->source(), $temp_source_l.$call_src_l.$temp_source_r, 'got right source code back');

$call = $temp->new_call($cname, $call_src_l, $call_src_r);
is( ref $call, 'Kephra::API::Call', 'call created with two sided source');
is( $call->run(5),               1, 'got result right');
is( $call->run(0),               1, 'got result right again');
is( $call->source(), $temp_source_l.$call_src_l.$temp_source_r.$call_src_r, 'got right source code back');

# create templates
$temp = Kephra::API::Call::Template->new($tname, $temp_source_l, $temp_source_r);
my $new_temp = $temp->new_template($cname, 1);
is( ref $new_temp,                             $class, 'templated created with two params');
is( ($new_temp->name()),                       $cname, 'created template has right name');
is( $new_temp->source_part_left(),  "1$temp_source_l", 'got left source part of created template');
is( $new_temp->source_part_right(),    $temp_source_r, 'got right source part of created template');
$new_temp = $temp->new_template($cname, 1, 2);
is( ref $new_temp,                               $class, 'templated created with three params');
is( ($new_temp->name()),                         $cname, 'created template has right name');
is( $new_temp->source_part_left(),"1$temp_source_l".'2', 'got left source part of created template');
is( $new_temp->source_part_right(),      $temp_source_r, 'got right source part of created template');
$new_temp = $temp->new_template($cname, 1, 2, 3);
is( ref $new_temp,                               $class, 'templated created with four params');
is( ($new_temp->name()),                         $cname, 'created template has right name');
is( $new_temp->source_part_left(),"1$temp_source_l".'2', 'got left source part of created template');
is( $new_temp->source_part_right(),   "3$temp_source_r", 'got right source part of created template');
$new_temp = $temp->new_template($cname, 1, 2, 3, 4);
is( ref $new_temp,                               $class, 'templated created with five params');
is( ($new_temp->name()),                         $cname, 'created template has right name');
is( $new_temp->source_part_left(),"1$temp_source_l".'2', 'got left source part of created template');
is( $new_temp->source_part_right(),"3$temp_source_r".'4','got right source part of created template');

# activity
$temp = Kephra::API::Call::Template->new($tname, $temp_source_l, $temp_source_r, 1);
is( ref $temp,                           $class, 'templated created with four params');
$call = $temp->new_call($cname, $call_src_l, $call_src_r);
$new_temp = $temp->new_template($cname, 1);
is( $call->is_active(),                       1, 'fourth parameter worked: created active call');
is( $new_temp->is_active(),                   1, 'derived template is also active');
$temp = Kephra::API::Call::Template->new($tname, $temp_source_l, $temp_source_r, 0);
$call = $temp->new_call($cname, $call_src_l, $call_src_r);
$new_temp = $temp->new_template($cname, 1);
is( $call->is_active(),                       0, 'fourth parameter worked: created inactive call');
is( $new_temp->is_active(),                   0, 'derived template is also not active');
$call = $temp->new_call($cname, $call_src_l, $call_src_r, 1);
is( $call->is_active(),                       1, 'fourth call creation parameter overwrote templated value: call is active');

# error messages
is( Kephra::API::Call::Template->new(1),undef, 'no template created with missing params');
like( pop(@error), qr/two to four parameter/, 'produced right error message');
is( Kephra::API::Call::Template->new(1,2,3,4,5),undef, 'no template created with three params');
like( pop(@error), qr/two to four parameter/, 'produced right error message');
is( $temp->new_template(1),            undef, 'no template created with missing params');
like( pop(@error), qr/two to five parameter/, 'new template produced right error message for not enought params');
is( $temp->new_template(1,2,3,4,5,4),  undef, 'no template created too much params');
like( pop(@error), qr/two to five parameter/, 'new template produced right error message for too much params');
is( $temp->new_call(1),                undef, 'no call created with missing params');
like( pop(@error), qr/two to four parameter/, 'new call produced right error message for not enought params');
is( $temp->new_call(1,2,3,4,5),        undef, 'no call created too much params');
like( pop(@error), qr/two to four parameter/, 'new call produced right error message for too much params');

exit 0;

;
