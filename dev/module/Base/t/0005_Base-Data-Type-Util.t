#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store; 
use Kephra::Base::Data::Type::Util;  

package TypeTester; 
use Test::More tests => 9;

is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => {}}),                  0 , 'basic type definition with no type name to substitute');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => ''}),                  1 , 'basic type definition with a basic type name to substitute');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => []}),                  1 , 'type definition with a parametric name to substitute');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => {}, parameter => {}}), 0 , 'parametric type definition with no type name to substitute');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => '', parameter => {}}), 1 , 'parametric type definition with one type name of parent to substitute');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => {}, parameter => ''}), 1 , 'parametric type definition with one type name of parameter to substitute');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => '', parameter => ''}), 2 , 'parametric type definition with two type names to substitute');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => '', parameter => {parent => ''}}), 2 , 'two: parameter parent and parent');
is( Kephra::Base::Data::Type::Util::can_substitude_names({name => 'a', parent => [], parameter => {parent => ''}}), 2 , 'two: parametric parent and parent of parameter');


exit 0;