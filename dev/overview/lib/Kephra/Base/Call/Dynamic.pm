use v5.14;
use warnings;

package Kephra::Base::Call::Dynamic;
use parent      qw(Kephra::Base::Call);
use Kephra::API qw/:log/;

sub new           {} # name ref|type src. act? --> obj                         =self:/name source coderef inputref ref_type active/

sub ref_type      {} #               --> str               getter
sub get_reference {} #               --> ref               getter
sub set_reference {} # ref           --> ref               setter

sub status        {} #               --> ref

1;
