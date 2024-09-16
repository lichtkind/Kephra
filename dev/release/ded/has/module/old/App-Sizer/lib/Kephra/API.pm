use v5.12;
use warnings;

package Kephra::API;
our $VERSION = 0.21;
use Scalar::Util qw(blessed looks_like_number);


BEGIN {  # because API is called first at start, to even work when mutually recursive included
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( error warning note report timestamp
                         is_widget is_panel is_sizer is_color is_font is_editor is_document is_doc_bar
    );
    our %EXPORT_TAGS = ( log => [qw(error warning note report)], );
    my %seen;                                                 # code for :all tag
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for keys %EXPORT_TAGS;
}

sub error        { say @_ }
sub warning      { say @_ }
sub note         { say @_ }
sub report       { say @_ }

# comparison checker
sub is_widget    {(blessed($_[0]) and $_[0]->isa('Wx::Window')              )  ? 1 : 0}
sub is_editor    {(blessed($_[0]) and $_[0]->isa('Kephra::App::Editor')     )  ? 1 : 0}
sub is_document  {(blessed($_[0]) and $_[0]->isa('Kephra::Document')        )  ? 1 : 0}
sub is_doc_bar   {(blessed($_[0]) and $_[0]->isa('Kephra::App::DocBar')     )  ? 1 : 0}
sub is_panel     {(blessed($_[0]) and $_[0]->isa('Wx::Panel')               )  ? 1 : 0}
sub is_sizer     {(blessed($_[0]) and $_[0]->isa('Wx::Sizer')               )  ? 1 : 0}
sub is_color     {(blessed($_[0]) and $_[0]->isa('Wx::Colour') and $_[0]->IsOk)? 1 : 0}
sub is_font      {(blessed($_[0]) and $_[0]->isa('Wx::Font') and $_[0]->IsOk)  ? 1 : 0}

'love and light';
