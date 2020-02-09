use v5.14;
use warnings;

package Kephra::API;
our $VERSION = 0.23;
use Scalar::Util qw(blessed);

BEGIN {  # because API is called first at start, to even work when mutually recursive included
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(error warning note report);
    our %EXPORT_TAGS = (log => [qw(error warning note report)],
    );
    my %seen;                                                 # code for :all tag
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for keys %EXPORT_TAGS;
    require Kephra::API::Message::Net;
}

sub error        { Kephra::API::Message::Net::send_message('error',  shift); return 0 }
sub warning      { Kephra::API::Message::Net::send_message('warning',shift); return 0 }
sub note         { Kephra::API::Message::Net::send_message('note',   shift); return 0 }
sub report       { Kephra::API::Message::Net::send_message('report', shift); return 0 }


#    Kephra::API::MessageNet::create_channel($_) for qw/error warning note report/;
#    Kephra::API::MessageNet::create_channel('say', 'out');
#    Kephra::API::MessageNet::add_source('say', $_) for qw/error warning note report/;
#    Kephra::API::MessageNet::add_target('say', 'say', 'say $msg->{"content"}');


'love and light';
