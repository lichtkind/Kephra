use v5.12;
use warnings;

package Kephra::API;
our $VERSION = 0.21;
use Scalar::Util qw(blessed);


BEGIN {  # because API is called first at start, to even work when mutually recursive included
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( app_window doc_bar editor document     caller_sub
                         is_widget is_panel is_sizer is_color is_font is_editor is_document is_doc_bar
    );
#                         error warn note report
    our %EXPORT_TAGS = (cmp => [qw(is_widget is_panel is_sizer is_color is_font is_editor is_document is_doc_bar)],
                        app => [qw(app_window doc_bar editor)],
#                        log => [qw(error warn note report)],
    );
    my %seen;                                                 # code for :all tag
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for keys %EXPORT_TAGS;
}

# application parts, environment
sub app          { $Kephra::App::app }
sub app_window   { $Kephra::App::win }
sub doc_panel    { $Kephra::App::Window::docpanel}
sub doc_bar      { $Kephra::App::Panel::Doc::bar } #doc_panel()->active_doc_bar()
sub all_doc_bar  { doc_panel()->all_doc_bar()   }
sub document     { Kephra::Document::Stash::active_doc()   }
sub all_documents{ Kephra::Document::Stash::all_docs()     }
sub editor       { Kephra::Document::Stash::active_editor()}
#sub error        { Kephra::MessageNet::send_msg('error', @_ ) } # sth. crashed
#sub warning      { Kephra::MessageNet::send_msg('warning'), @_} # mostly bad parameter data prevented work 
#sub note         { Kephra::MessageNet::send_msg('note'), @_   } # potential problems
#sub report       { Kephra::MessageNet::send_msg('report'), @_ } # debugging

# comparison checker
sub is_widget    {(blessed($_[0]) and $_[0]->isa('Wx::Window')              )  ? 1 : 0}
sub is_editor    {(blessed($_[0]) and $_[0]->isa('Kephra::App::Editor')     )  ? 1 : 0}
sub is_document  {(blessed($_[0]) and $_[0]->isa('Kephra::Document')        )  ? 1 : 0}
sub is_tab_bar   {(blessed($_[0]) and $_[0]->isa('Kephra::App::Bar::Tab')   )  ? 1 : 0}
sub is_panel     {(blessed($_[0]) and $_[0]->isa('Wx::Panel')               )  ? 1 : 0}
sub is_sizer     {(blessed($_[0]) and $_[0]->isa('Wx::Sizer')               )  ? 1 : 0}
sub is_color     {(blessed($_[0]) and $_[0]->isa('Wx::Colour') and $_[0]->IsOk)? 1 : 0}
sub is_font      {(blessed($_[0]) and $_[0]->isa('Wx::Font') and $_[0]->IsOk)  ? 1 : 0}


sub caller_sub   { (caller($_[0]))[3] } # denn es geht über api und methode


'love and light';
