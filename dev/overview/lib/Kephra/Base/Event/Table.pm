use v5.14;
use warnings;

package Kephra::Base::Event::Table;
use Kephra::API  qw/:log/;
use Kephra::Base::Event;

my %table = ( call => {},   sub => {},             path => {},
              active => {before => {}, main => {}, after=> {} },  );


sub state        {} # state                                                    =state:open!, close, mute, shutdown(mute+del all)


sub create_event {} # EID state? --> 1|0                                       =state:/active frozen halted/
sub rename_event {} # EID newID  --> 1|0
sub has_event    {} # EID        --> 1|0
sub list_events  {} #            --> [EID]
sub delete_event {} # EID        --> Hashref(event)

sub freeze_event {} # EID state? --> 1|0
sub thaw_event   {} # EID        --> 1|0
sub trigger_event{} # EID        --> 1|0
sub event_state  {} # EID state? --> state|1|0


sub add_call     {} # EID CID time? str(code) --> 1|0                          =time:/before main! after/
sub get_call     {} # EID CID time?           --> str(code)|0
sub list_calls   {} # EID     time?           --> [CID]
sub remove_call  {} # EID CID time?           --> Hashref(call)


sub report_status        {} # event table status to report channel
                            # list events with all details

1;

__END__

format: app.toolbar.click

active: listens to trigger commands
frozen: ignores trigger commands
halted: trigger on thaw, when trig cmd recieved while halted

before main after
