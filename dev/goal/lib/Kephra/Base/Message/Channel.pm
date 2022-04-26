use v5.14;
use warnings;

package Kephra::Base::Message::Channel;
use parent qw(Kephra::Base::Object);
use Kephra::API qw/:log/;
use Kephra::Base::Message;
use Kephra::Base::Object::Store;

sub new            {} # name type? state? size? --> obj                        =self:/source target filter msgs/

sub name           {} #         --> str
sub type           {} #         --> str                                        =type:/!in out/

sub get_state      {} #         --> state                                      =state:/!open hold closed/
sub set_state      {} # state   --> 1
sub get_size       {} #         --> int
sub set_size       {} # int?    --> 1                                          !20

sub add_filter     {} # src     --> FID
sub get_filter_IDs {} #         --> [FID]
sub get_filter     {} # FID     --> call
sub remove_filter  {} # FID     --> 1

sub add_target     {} # source  --> TID
sub get_target_IDs {} #         --> [TID]
sub get_target     {} # TID     --> call
sub remove_target  {} # TID     --> 1

sub append_message {} # msg     --> int
sub message_count  {} # kind?   --> int                                        =kind:/!accepted rejected recieved/
sub remove_messages{} #         --> [msgs]

sub status         {} #         --> ref

1;
