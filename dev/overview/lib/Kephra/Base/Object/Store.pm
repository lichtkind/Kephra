use v5.14;
use warnings;

package Kephra::Base::Object::Store;
use parent qw(Kephra::Base::Object);
use Kephra::API qw/:log/;
use Kephra::Base::Class::Method::Hook;
use Kephra::Base::Object::Queue;

sub new {} # pkg class {getter => setter}? hsize? factory? --> obj
                             #                                                 =class:classname of items 
                             #                                                 =size of history(int !0)
                             #                                                 =factory_type: call dynacall template dynatemplate

sub new_item              {} # [params]? [temp]?   --> ID item                 =temp:code templates for call that creates item
sub add_item              {} # item                --> ID item
sub remove_item           {} # item|ID             --> item

sub item_class            {} #                     --> str
sub delegate_method       {} # name @param         --> [ret]

sub get_item_IDs          {} #                     --> [ID]
sub get_ID_by_item        {} # item                --> ID
sub get_item_by_ID        {} # ID                  --> item

sub item_attributes       {} #                     --> [str]
sub get_attribute_values  {} # getter              --> [val]
sub get_item_by_atttibute {} # getter val          --> [item]

sub has_history           {} #                     --> bool
sub use_item              {} # item|ID             --> bool                    =was it in history?
sub get_latest_item       {} # nr?                 --> item

sub status                {} #                     --> ref


1;
