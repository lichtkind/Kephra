use v5.14;
use warnings;

package Kephra::Base::Message::Net;
use Kephra::API qw/:log/;
use Kephra::Base::Object::Store;
use Kephra::Base::Message::Channel;

sub new                  {} #                        --> obj                   =self:/channel/

sub get_state            {} #                        --> state                 =state:/!open, closed, shut_down/
sub set_state            {} # state                  --> 1               #     =shut_down: close and delete all msg

sub create_channel       {} # CID type? state? size? --> channel               =CID:names(str), ot internal ID
sub get_channel_names    {} # type?                  --> [CID]
sub get_channel          {} # CID                    --> channel
sub delete_channel       {} # CID                    --> 1

sub connect_channel      {} # inCID outCID           --> 1
sub get_connected_channel{} # CID                    --> [CID]
sub disconnect_channel   {} # inCID outCID?          --> int

sub send_message         {} # CID str|hash           --> 1

sub status               {} #                        --> ref

1;

