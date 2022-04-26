use v5.14;
use warnings;

package Kephra::API;
our $VERSION = 0.23;
use Scalar::Util qw(blessed);
use Kephra::API::Call::Template;

BEGIN {  # because API is called first at start, to even work when mutually recursive included
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(error warning note report   blessed is_object is_call is_dynacall);
    our %EXPORT_TAGS = (log => [qw(error warning note report)],
                       test => [qw/blessed is_object is_call is_dynacall/],
    );
    my %seen;                                                 # code for :all tag
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for keys %EXPORT_TAGS;
}

sub error        { say @_; undef }
sub warning      { say @_; undef }
sub note         { say @_; undef }
sub report       { say @_; undef }

sub is_object    { blessed($_[0])                                              ? 1 : 0}
sub is_call      {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call'))         ? 1 : 0}
sub is_dynacall  {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call::Dynamic'))? 1 : 0}

'love and light';
