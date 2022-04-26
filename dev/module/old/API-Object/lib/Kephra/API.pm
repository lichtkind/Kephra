use v5.14;
use warnings;

package Kephra::API;
our $VERSION = 0.23;
use Kephra::API::Data::Type qw/:all/;
use Kephra::API::Package qw/:all/;
use Kephra::API::Class qw/:all/;

BEGIN {  # because most other modules depend on these symbols the central API has to export first
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = (@{$Kephra::API::Package::EXPORT_TAGS{all}},
                      @{$Kephra::API::Data::Type::EXPORT_TAGS{all}},
                     qw/error warning note report  create_counter date_time sub_caller/);
    our %EXPORT_TAGS = (log  => [qw(error warning note report)],
                        pkg  => [@{$Kephra::API::Package::EXPORT_TAGS{all}}],
                        obj  => [qw/attribute method parameter is_object/],
                        util => [qw(create_counter date_time sub_caller)],                        
                        test => ['blessed', @{$Kephra::API::Data::Type::EXPORT_TAGS{test}}],
    );
    my %seen;                                                 # code for :all tag
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for keys %EXPORT_TAGS;
    require Kephra::API::Object;
}

# :log
sub error        { say @_; undef }
sub warning      { say @_; undef }
sub note         { say @_; undef }
sub report       { say @_; undef }

# :util
sub create_counter { Kephra::API::Call->new('state $cc = 0; $cc++;') }
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

'love and light';
