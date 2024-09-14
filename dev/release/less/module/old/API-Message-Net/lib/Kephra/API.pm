use v5.14;
use warnings;

package Kephra::API;
our $VERSION = 0.242;
use Scalar::Util qw/blessed looks_like_number/;
use Time::HiRes qw/gettimeofday/;
use Kephra::API::Package qw/count_sub has_sub call_sub package_loaded/;

BEGIN {  # because most other modules depend on these symbols the central API has to export first
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw/blessed looks_like_number    count_sub has_sub call_sub package_loaded
                        error warning note report
                        date_time sub_caller create_counter
                        is_int is_uc is_object is_call is_dynacall is_template is_dynatemplate is_widget is_panel is_sizer is_color is_font 
    /;
    our %EXPORT_TAGS = (log  => [qw/error warning note report/],
                        pkg  => [qw/count_sub has_sub call_sub package_loaded/],
                        util => [qw/create_counter sub_caller date_time/],
                        test => [qw/looks_like_number is_int is_uc is_object is_call is_dynacall is_template is_dynatemplate 
                                    blessed is_widget is_panel is_sizer is_color is_font/],
    );
    my %seen;                                                 # code for :all tag
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for keys %EXPORT_TAGS;
}

use Kephra::API::Message::Net;
my $central_msg_net;
 
END {
    $central_msg_net = Kephra::API::Message::Net->new();
    $central_msg_net->create_channel($_) for qw/error warning note report/;
   # $central_msg_net->create_channel('shell', 'out');
   # $central_msg_net->connect_channel($_, 'shell') for qw/error warning note report/;
   # $central_msg_net->get_channel('shell')->add_target('say $msg->time(), " ",  $msg->content()');
}


# :app


# :log
sub error         { $central_msg_net->send_message('error',  shift); undef }
sub warning       { $central_msg_net->send_message('warning',shift); undef }
sub note          { $central_msg_net->send_message('note',   shift); undef }
sub report        { $central_msg_net->send_message('report', shift); undef }

# :util
sub create_counter{ Kephra::API::Call->new('counter', 'state $cc = 0; $cc++;') }
sub date_time {
    my @time = (localtime);
    sprintf ("%02u.%02u.%u", $time[3], $time[4]+ 1, $time[5]+ 1900),
    sprintf ("%02u:%02u:%02u:%03u", @time[2,1,0], int((gettimeofday())[1]/1_000));
}
sub sub_caller {
    my($depth, $file, $line, $caller, $pos, $sub, $package) = (shift // 1);
    while (1) {
        ++$depth;
        ($file, $line, $caller) = ((caller($depth-1))[1,2], (caller($depth))[3]);
        return unless $caller;
        $pos = rindex($caller, '::');
        $package = substr($caller, 0, $pos);
        $sub     = substr($caller, $pos+2);
        next if substr($sub, 0, 1) eq '_';
        ($package, $sub) = ("$package::$sub",'') if is_uc( substr($sub,0,1) );
        next if $package eq __PACKAGE__ and $sub;
        last;
    }
    ($file, $line, $sub, $package);
}

# :test
sub is_int         {(defined($_[0]) and int $_[0] eq $_[0])                      ? 1 : 0}
sub is_uc          {(defined($_[0]) and uc $_[0] eq $_[0])                       ? 1 : 0}
sub is_object      { blessed($_[0])                                              ? 1 : 0}
sub is_call        {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call')         )? 1 : 0}
sub is_dynacall    {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call::Dynamic'))? 1 : 0}
sub is_template    {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call::Template'))? 1 : 0}
sub is_dynatemplate{(blessed($_[0]) and $_[0]->isa('Kephra::API::Call::Dynamic::Template'))? 1 : 0}
sub is_widget      {(blessed($_[0]) and $_[0]->isa('Wx::Window')                )? 1 : 0}
sub is_panel       {(blessed($_[0]) and $_[0]->isa('Wx::Panel')                 )? 1 : 0}
sub is_sizer       {(blessed($_[0]) and $_[0]->isa('Wx::Sizer')                 )? 1 : 0}
sub is_color       {(blessed($_[0]) and $_[0]->isa('Wx::Colour') and $_[0]->IsOk)? 1 : 0}
sub is_font        {(blessed($_[0]) and $_[0]->isa('Wx::Font') and $_[0]->IsOk  )? 1 : 0}

'love and light';
