use v5.14;
use warnings;

package Kephra::Base::Object::Queue;
use parent qw(Kephra::Base::Object);
use Kephra::API qw/:log is_object looks_like_number/;

sub new           {} # class frontstate backstate max min  --> obj             =class: of all items

sub is_front_closed{} #         --> bool                                       =state:/!open closed/
sub close_front    {} # bool    --> bool
sub is_back_closed {} #         --> bool                                       =state:/!open closed/
sub close_back     {} # bool    --> bool

sub get_min_quota  {} #         --> int
sub set_min_quota  {} # int?    --> int                                        !0 (no minimum)
sub get_max_quota  {} #         --> int
sub set_max_quota  {} # int?    --> int|[item]                                 !0 (inf capacity)

sub item_class     {} #                --> str
sub item_count     {} #                --> int
sub item_position  {} # item           --> int|-1
sub get_item       {} # pos            --> item

sub append_item    {} # item unique?   --> [item]|1                            =1 (success) is implicit when getting items
sub prepend_item   {} # item unique?   --> [item]|1                            =item that fall out, because others where pushed in
sub remove_front   {} # nr? allornone? --> [item]                              =! all possible if no param 
sub remove_item    {} # item           --> int                                 =int: how many refs to that item removed


sub status         {} #                --> ref

1
