use v5.14;
use warnings;

package Kephra::API;
our $VERSION = 0.23;
use Scalar::Util qw/blessed looks_like_number/;
use Time::HiRes qw/gettimeofday/;
use Kephra::API::Package qw/count_sub has_sub call_sub package_loaded/;

BEGIN {  # because API is called first at start, to even work when mutually recursive included
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(blessed date_time looks_like_number   package_loaded count_sub has_sub call_sub
                        error warning note report
                        create_counter sub_caller date_time
                        is_int is_uc is_object is_call is_object is_call 
                        is_widget is_panel is_sizer is_color is_font is_editor is_document is_doc_bar
                        app_window doc_bar editor document 
    );
    our %EXPORT_TAGS = (app  => [qw(app_window doc_bar editor)],
                        log  => [qw(error warning note report)],
                        pkg  => [qw(package_loaded count_sub has_sub call_sub)],
                        util => [qw/create_counter sub_caller date_time/],

                        test => [qw(is_int is_object is_call blessed looks_like_number 
                                    is_widget is_panel is_sizer is_color is_font is_editor is_document is_doc_bar)],
    );
    my %seen;                                                 # code for :all tag
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for keys %EXPORT_TAGS;
    require Kephra::API::Call::Template;
    require Kephra::API::Object::Store;
}

# :app application parts, inner env
sub app          { $Kephra::App::app }
sub app_window   { $Kephra::App::win }
sub doc_panel    { $Kephra::App::Window::docpanel}
sub doc_bar      { $Kephra::App::Panel::Doc::bar } #doc_panel()->active_doc_bar()
sub all_doc_bar  { doc_panel()->all_doc_bar()    }
sub document     { Kephra::Document::Stash::active_doc()   }
sub all_documents{ Kephra::Document::Stash::all_docs()     }
sub editor       { Kephra::Document::Stash::active_editor()}

# :log
sub error        { say @_; return undef }
sub warning      { say @_; return undef }
sub note         { say @_; return undef }
sub report       { say @_; return undef }


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

# :test
sub is_int       {(defined($_[0]) and int $_[0] eq $_[0])                      ? 1 : 0}
sub is_uc        {(defined($_[0]) and uc $_[0] eq $_[0])                       ? 1 : 0}
sub is_object    { blessed($_[0])                                              ? 1 : 0}
sub is_call      {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call')         )? 1 : 0}
sub is_editor    {(blessed($_[0]) and $_[0]->isa('Kephra::App::Editor')       )? 1 : 0}
sub is_tab_bar   {(blessed($_[0]) and $_[0]->isa('Kephra::App::Bar::Tab')     )? 1 : 0}
sub is_document  {(blessed($_[0]) and $_[0]->isa('Kephra::Document')          )? 1 : 0}
sub is_widget    {(blessed($_[0]) and $_[0]->isa('Wx::Window')                )? 1 : 0}
sub is_panel     {(blessed($_[0]) and $_[0]->isa('Wx::Panel')                 )? 1 : 0}
sub is_sizer     {(blessed($_[0]) and $_[0]->isa('Wx::Sizer')                 )? 1 : 0}
sub is_color     {(blessed($_[0]) and $_[0]->isa('Wx::Colour') and $_[0]->IsOk)? 1 : 0}
sub is_font      {(blessed($_[0]) and $_[0]->isa('Wx::Font') and $_[0]->IsOk  )? 1 : 0}
