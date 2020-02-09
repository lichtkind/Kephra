use v5.14;
use warnings;

package Kephra::Base::Object::Method::Hook;
use Kephra::API qw/:log/;
use Kephra::Base::Call;


sub add_before    {}  # obj method HID code --> call                           =code params:self [params] [HID, ID]
sub add_after     {}  # obj method HID code --> call                           =code params:self [params] [HID, ID] [before_ret{ID}] [main_ret]

sub get_before_IDs{}  # obj method          --> [HID]
sub get_after_IDs {}  # obj method          --> [HID]
sub get_methods   {}  # obj                 --> [method]

sub get_before    {}  # obj method HID      --> call
sub get_after     {}  # obj method HID      --> call

sub remove_before {}  # obj method HID      --> call
sub remove_after  {}  # obj method HID      --> call

1;
