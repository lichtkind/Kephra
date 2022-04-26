use v5.16;
use warnings;

package Kephra::Base::Object;
use Kephra::Base::Object::CodeSnippet;
use Kephra::Base::Object::Queue;
use Kephra::Base::Object::Store;

my %required_methods_check;
my @required_methods = qw/status/;



1;
