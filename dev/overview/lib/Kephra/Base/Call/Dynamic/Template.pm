use v5.14;
use warnings;

package Kephra::Base::Call::Dynamic::Template;
use parent      qw(Kephra::Base::Call::Template);
use Kephra::API qw/:log/;
use Kephra::Base::Call::Dynamic;

sub new              {} # name ref|type srcl srcr? act?    --> obj             =self:/source_left source_right/
sub new_dynatemplate {} # name ref|type sll slr? srl? srr? --> obj             =sll:Source Left of (former) Left part 
sub new_dynacall     {} # name ref|type srcl srcr? act?    --> dynacall

sub ref_type         {} #                    --> str               getter
sub get_reference    {} #                    --> ref               getter
sub set_reference    {} # ref                --> bool              setter

sub status           {} #                    --> ref

1;
