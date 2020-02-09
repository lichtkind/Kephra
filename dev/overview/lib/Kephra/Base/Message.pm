use v5.14;
use warnings;

package Kephra::Base::Message;
use parent qw(Kephra::Base::Object);
use Kephra::API qw/:log date_time/;


sub new        {} # text/hash  --> obj
sub set_channel{} # dir name   --> bool

sub content    {} #            --> str
sub topic      {} #            --> str
sub date       {} #            --> str
sub time       {} #            --> str
sub sender     {} #            --> obj
sub channel_in {} #            --> str
sub channel_out{} #            --> str

sub status     {} #            --> ref


1;
