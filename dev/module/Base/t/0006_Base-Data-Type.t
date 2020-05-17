#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}


package TypeTester; 
use Kephra::Base::Data::Type qw/:all/;
use Test::More tests => 4;

my $btclass = 'Kephra::Base::Data::Type::Basic';
my $ptclass = 'Kephra::Base::Data::Type::Parametric';

my $Tdef = {name=> 'value', help => 'defined value', code => 'defined $value', default => ''};
my $Tval = create_type( $Tdef );

is(ref $Tval, $btclass,           'sub symbol "create_type" imported');
is(check_type('int', 5), '',      'sub symbol "check_type" imported"');
is(is_type_known('int'), 1,       'sub symbol "is_type_known" imported"');
is('num' ~~ [guess_type(2.3)], 1, 'sub symbol "guess_type" imported');


exit 0;

__END__
is( 'num' ~~ [guess_type(2.3)],         1, 'sub guess_type got imported');