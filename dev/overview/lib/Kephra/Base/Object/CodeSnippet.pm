use v5.16;
use warnings;

package Kephra::Base::Object::CodeSnippet;
use parent      qw/Kephra::Base::Object/;
use Kephra::API qw/:log/;

sub new          {} # name src. act?  --> obj                                  =self:/name source coderef active/
sub run          {} # @param          --> retval

sub name         {} #                 --> str               getter
sub source       {} #                 --> str               getter
sub is_active    {} #                 --> bool              getter
sub set_active   {} # bool            --> bool              setter

sub status       {} #                 --> ref

1;
