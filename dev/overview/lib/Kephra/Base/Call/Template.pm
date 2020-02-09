use v5.14;
use warnings;

package Kephra::Base::Call::Template;
use parent      qw(Kephra::Base::Object);
use Kephra::API qw/:log/;
use Kephra::Base::Call;

sub new              {} # name srcl srcr? act.?    --> obj                     =self:/name active source_left source_right/
sub new_template     {} # name sll slr? srl? srr?  --> obj                     =sll:Source Left of (former) Left part
sub new_call         {} # name srcl srcr? act.?    --> call

sub name             {} #                  --> str               getter
sub source_part_left {} #                  --> str               getter
sub source_part_right{} #                  --> str               getter

sub is_active        {} #                  --> bool              getter        =active: to create active calls
sub set_active       {} # bool             --> bool              setter

sub status           {} #                  --> ref

1;
