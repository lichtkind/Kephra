#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 108;

BEGIN { unshift @INC, 'lib', '../lib', 't', '.'}
use TestClass;
use Kephra::API::Call::Dynamic::Template;

my (@warning, @error, @note, @report);
my ($class, $call_class, $tname, $ntname, $cname) = ('Kephra::API::Call::Dynamic::Template', 'Kephra::API::Call::Dynamic', 'template', 'nt', 'call');
no strict 'refs';
no warnings;
*{$class.'::error'}    = sub {push @error,  shift; undef };
*{$class.'::warning'}  = sub {push @warning,shift; undef };
*{$class.'::note'}     = sub {push @note,   shift; undef };
*{$class.'::report'}   = sub {push @report, shift; undef };
*{$call_class.'::error'}   = sub { undef; };
*{$call_class.'::warning'} = sub { undef; };
*{$call_class.'::note'}    = sub { undef; };
*{$call_class.'::report'}  = sub { undef; };
use strict;
use warnings;

# simple getter
my $ref = TestClass->new();
my ($temp_source_l, $temp_source_r) = ('no warnings "void"; my $d = shift;', '$d - 1;');
my ($call_src_l, $call_src_r) = ('$d *= $ref->get();', '$d - 1;');
my $temp = Kephra::API::Call::Dynamic::Template->new($tname, $ref, $temp_source_l, $temp_source_r, 0);

is( ref $temp,                           $class, 'both sided templat created');
is( $temp->name(),                       $tname, 'got template name');
is( $temp->ref_type(),                 ref $ref, 'got ref type');
is( $temp->source_part_left(),   $temp_source_l, 'got left part of source');
is( $temp->source_part_right(),  $temp_source_r, 'got right part of source');
is( $temp->get_reference(),                $ref, 'got ref that will be used by call');
is( $temp->is_active(),                       0, 'template creates not active calls');

# setter
$ref = TestClass->new(10);
$ref->set(11);
isnt( $temp->get_reference(),              $ref, 'ref is different than stored');
is( $temp->set_reference($ref),            $ref, 'changed ref');
is( $temp->get_reference(),                $ref, 'set successfully ref');
is( $temp->set_active(1),                     1, 'changed active state');
is( $temp->is_active(),                       1, 'template creates now active calls');
is( $temp->set_active(0),                     0, 'changed active state');
is( $temp->is_active(),                       0, 'created calls are now passive');

# propagation of setter values to dynacalls
my $nref = TestClass->new();
my $call = $temp->new_dynacall($cname, $nref, $call_src_l, $call_src_r, 1);
is( ref $call,                      $call_class, 'call created with full parameter on template with full');
is( $call->name(),                       $cname, 'forwarded name correctly to created call');
is( $call->ref_type(),                ref $nref, 'got ref type');
is( $call->get_reference(),               $nref, 'forwarded ref correctly to created call');
is( $call->is_active(),                       1, 'state correctly overwritten from template value');
is( $call->source(), $temp_source_l.$call_src_l.$temp_source_r.$call_src_r, 'forwarded sources correctly to created call');

$call = $temp->new_dynacall('', '', $call_src_l);
is( ref $call,                      $call_class, 'call created with minimal parameter in template with full params');
is( $call->name(),                           '', 'empty name forewarded correctly');
is( $call->ref_type(),                 ref $ref, 'got ref type');
is( $call->get_reference(),                $ref, 'empty ref forwarded correctly');
is( $call->is_active(),                       0, 'call state forwarded correctly');
is( $call->source(), $temp_source_l.$call_src_l.$temp_source_r, 'joined sources correctly to created call source');

$temp = Kephra::API::Call::Dynamic::Template->new('', 'TestClass', $temp_source_l);
$call = $temp->new_dynacall($cname, $nref, $call_src_l, $call_src_r, 0);
is( ref $call,                      $call_class, 'call created with full parameter on template with minimal params');
is( $call->name(),                       $cname, 'forwarded name correctly to created call');
is( $call->ref_type(),                ref $nref, 'got ref type');
is( $call->get_reference(),               $nref, 'forwarded ref correctly to created call');
is( $call->is_active(),                       0, 'state correctly overwritten from template value');
is( $call->source(), $temp_source_l.$call_src_l.$call_src_r, 'forwarded sources correctly to created call');

$call = $temp->new_dynacall('', '', $call_src_l);
is( ref $call,                      $call_class, 'call created with minimal parameter on template with minimal params');
is( $call->name(),                           '', 'empty name forwarded correctly');
is( $call->ref_type(),              'TestClass', 'ref type forewarded');
is( $call->get_reference(),               undef, 'no ref could be forwarded');
is( $call->is_active(),                       1, 'got default template state for dynacalls');
is( $call->source(), $temp_source_l.$call_src_l, 'joined sources correctly to created call source');

$call = $temp->new_dynacall('', '', $call_src_l, '', 0);
is( $call->ref_type(),              'TestClass', 'ref type forewarded');
is( $call->get_reference(),               undef, 'no ref could be forwarded');
is( $call->is_active(),                       0, 'overwritten default template state for dynacalls');
is( $call->source(), $temp_source_l.$call_src_l, 'joined sources correctly also with empty template parts');

$temp->set_reference($ref);
$call = $temp->new_dynacall($cname, '', $call_src_l);
is( $call->ref_type(),              'TestClass', 'ref type forewarded');
is( $call->get_reference(),                $ref, 'new call got newly in template set ref');


# propagation of setter values to derived templates
$temp = Kephra::API::Call::Dynamic::Template->new($tname, $ref, $temp_source_l, $temp_source_r, 0);
my $ntemp = $temp->new_dynatemplate($ntname, $nref, 1, 2, 3, 4);
is( ref $ntemp,                          $class, 'derived templated created from template with max params');
is( $ntemp->name(),                     $ntname, 'got newly derived name');
is( $ntemp->get_reference(),              $nref, 'got ref from method call that created derived template');
is( $ntemp->ref_type(),               ref $nref, 'got new ref type');
is( $ntemp->source_part_left(),'1'.$temp_source_l.'2', 'got left part of derived source');
is( $ntemp->source_part_right(),'3'.$temp_source_r.'4','got right part of derived source');
is( $ntemp->is_active(),                      0, 'derived template has same astivity state');

$ntemp = $temp->new_dynatemplate('', '', 1,2,3);
is( $ntemp->source_part_left(),"1$temp_source_l".'2','got left part of derived source');
is( $ntemp->source_part_right(), "3$temp_source_r", 'got right part of derived source');

$ntemp = $temp->new_dynatemplate('', '', 1,2);
is( $ntemp->source_part_left(),"1$temp_source_l".'2','got left part of derived source');
is( $ntemp->source_part_right(), $temp_source_r, 'got right part of derived source');

$temp->set_active(1);
$ntemp = $temp->new_dynatemplate('', '', 1 );
is( ref $ntemp,                          $class, 'derived templated created with minimal params from temp with max params');
is( $ntemp->name(),                          '', 'got empty name');
is( $ntemp->get_reference(),               $ref, 'got ref from father template');
is( $ntemp->ref_type(),                ref $ref, 'got new ref type');
is( $ntemp->source_part_left(),"1$temp_source_l",'got left part of derived source');
is( $ntemp->source_part_right(), $temp_source_r, 'got right part of derived source');
is( $ntemp->is_active(),                      1, 'derived template has same astivity state');

$ntemp = $temp->new_dynatemplate('', '', '', 2);
is( $ntemp->source_part_left(),$temp_source_l.'2','got left part of derived source');
is( $ntemp->source_part_right(), $temp_source_r, 'got right part of derived source');

$ntemp = $temp->new_dynatemplate('', '', '', '', 3);
is( $ntemp->source_part_left(),  $temp_source_l,'got left part of derived source');
is( $ntemp->source_part_right(),'3'.$temp_source_r,'got right part of derived source');

$ntemp = $temp->new_dynatemplate('', '', '', '', '', 4);
is( $ntemp->source_part_left(),  $temp_source_l,'got left part of derived source');
is( $ntemp->source_part_right(), $temp_source_r.'4','got right part of derived source');

$temp = Kephra::API::Call::Dynamic::Template->new($tname, $ref, $temp_source_l);
$ntemp = $temp->new_dynatemplate($ntname, $nref, 1, 2, 3, 4);
is( ref $ntemp,                          $class, 'derived templated created with maximal parameter from template with min params');
is( $ntemp->name(),                     $ntname, 'got newly derived name');
is( $ntemp->get_reference(),              $nref, 'got ref from method call that created derived template');
is( $ntemp->ref_type(),               ref $nref, 'got new ref type');
is( $ntemp->source_part_left(),'1'.$temp_source_l.'2', 'got left part of derived source');
is( $ntemp->source_part_right(),           '34', 'got right part of derived source');
is( $ntemp->is_active(),                      1, 'derived template has same astivity state');

$ntemp = $temp->new_dynatemplate($ntname, '', 1, 2, 3);
is( ref $ntemp,                          $class, 'derived templated created on template with max params from template with minimal params');
is( $ntemp->name(),                     $ntname, 'got own name');
is( $ntemp->get_reference(),               $ref, 'got ref from method call that created derived template');
is( $ntemp->ref_type(),                ref $ref, 'got new ref type');
is( $ntemp->source_part_left(),'1'.$temp_source_l.'2', 'got left part of derived source');
is( $ntemp->source_part_right(),            '3', 'got right part of derived source');
is( $ntemp->is_active(),                      1, 'derived template has same astivity state');

$ntemp = $temp->new_dynatemplate('', $nref, 1, 2);
is( $ntemp->source_part_left(),'1'.$temp_source_l.'2', 'got left part of derived source');
is( $ntemp->source_part_right(),             '', 'got right part of derived source');

$ntemp = $temp->new_dynatemplate('', $nref, 1);
is( $ntemp->source_part_left(),'1'.$temp_source_l, 'got left part of derived source');
is( $ntemp->source_part_right(),             '', 'got right part of derived source');

$ntemp = $temp->new_dynatemplate('', '', '', 2);
is( $ntemp->source_part_left(),$temp_source_l.'2','got left part of derived source');
is( $ntemp->source_part_right(),               '', 'got right part of derived source');

$ntemp = $temp->new_dynatemplate('', '', '', '', 3);
is( $ntemp->source_part_left(),  $temp_source_l,'got left part of derived source');
is( $ntemp->source_part_right(),            '3','got right part of derived source');

$ntemp = $temp->new_dynatemplate('', '', '', '', '', 4);
is( $ntemp->source_part_left(),  $temp_source_l,'got left part of derived source');
is( $ntemp->source_part_right(),            '4','got right part of derived source');


#'', 'TestClass'
# status

# error messages
is( Kephra::API::Call::Dynamic::Template->new(1,$ref), undef, 'no template created with too little params');
like( pop(@error), qr/three to five parameter/, 'produced right error message');
is( Kephra::API::Call::Dynamic::Template->new(1,2,3,4,5,6), undef, 'no template created with too many params');
like( pop(@error), qr/three to five parameter/, 'produced right error message');
is( $temp->new_dynatemplate(1,2),            undef, 'no derived template created with missing params');
like( pop(@error), qr/three to six parameter/,  'new template produced right error message for not enought params');
is( $temp->new_dynatemplate(1,2,3,4,5,6,7), undef,  'no derived template created too much params');
like( pop(@error), qr/three to six parameter/,  'new template produced right error message for too much params');
is( $temp->new_dynatemplate(1,[],3),        undef,  'no derived template created not matching ref');
like( pop(@error),qr/referece has to have type/,'new template produced right error message for none matching ref');
is( $temp->new_dynacall(1,2),           undef,  'no dynacall created with missing params');
like( pop(@error),qr/three to five parameter/,  'new call produced right error message for not enought params');
is( $temp->new_dynacall(1,2,3,4,5,6),   undef,  'no dynacall created too much params');
like( pop(@error), qr/three to five parameter/, 'new call produced right error message for too much params');
is( $temp->new_dynacall(1,[],3),        undef,  'no dynacall created with not matching ref');
like( pop(@error),qr/referece has to have type/,'new dynacall produced right error message for none matching ref');

exit 0;

;
