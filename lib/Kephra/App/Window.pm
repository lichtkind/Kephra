use v5.12;
use warnings;

package Kephra::App::Window;

use base qw(Wx::Frame);
use Kephra::API qw(document is_document);
use Kephra::App::Dialog;
use Kephra::App::Splitter;
use Kephra::App::Panel;
use Kephra::App::Panel::Doc;


our ($docpanel, %splitter);

sub new {
    my($class, $parent) = @_;
    my $self = $class->SUPER::new( undef, -1, '', [-1,-1], [1000,800] );
    $self->CreateStatusBar(4);
    $self->SetStatusWidths(100, 60, 75, -1);

    my $main_panel = Wx::Panel->new($self, -1);
    $docpanel = Kephra::App::Panel::Doc->new( $main_panel );
    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    $sizer->Add( $docpanel,  1, &Wx::wxTOP | &Wx::wxLEFT | &Wx::wxGROW);
    $main_panel->SetSizer($sizer);
    Wx::Event::EVT_CLOSE ($self,  sub { Kephra::App::shut_down() });
    return $self;
}

sub set_title {
	my ($self, $status) = @_;
	my $msg = $Kephra::NAME;
	$msg .= $status if defined $status;
	$self->SetTitle($msg);
}

sub default_title_update {
	my ($self) = @_;
	my $doc = document();
	return unless is_document($doc);
	my $msg = $doc->{'file_path'};
	$msg = $doc->{'title'} unless $msg;
	$msg .= '*' if $doc->{'editor'}->GetModify;
	$self->set_title($msg);
}

1;

__END__

sub OnInit {
    my( $app ) = @_;
    my( $frame ) = Wx::Frame->new(undef, -1, "Kephra CP list func  proto : ".__FILE__, [-1,-1], [-1, -1 ] );
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    my $main_panel = Wx::Panel->new($frame, -1);
    
    my $ed = Wx::TextCtrl->new($main_panel, -1, 'init',[-1,-1],[-1,-1], &Wx::wxTE_MULTILINE);
    my $list = Wx::ListCtrl->new($main_panel, -1, [-1,-1],[-1,-1], &Wx::wxLC_SMALL_ICON);
#    $list->InsertColumn( 1, "Type" );
#    $list->InsertColumn( 2, "Amount" );
#    $list->InsertColumn( 3, "Price" );
    
    map { $list->InsertStringItem( $_ , ' str '.$_) } 0..5;
    Wx::Window::SetFocus($list);


    Wx::Event::EVT_LIST_ITEM_ACTIVATED($list, -1, sub {
        my ($list, $event) = @_;
        
        $ed->AppendText(' - '.$event->GetColumn()); # GetIndex GetLabel
    });

    my $sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $sizer->Add($ed, 1, &Wx::wxTOP | &Wx::wxLEFT | &Wx::wxGROW);
    $sizer->Add($list, 1, &Wx::wxTOP | &Wx::wxGROW);
    $main_panel->SetSizer($sizer);
    $frame->Centre( );
    $frame->Show( 1 );
    $app->SetTopWindow( $frame );
  1;
}

__END__

    $sizer->Add( $frame->{line} ,  0 , wxTOP|wxGROW , 0);
    $sizer->Add( $frame->{tabbar} ,  0 , wxTOP|wxGROW , 0);
    $sizer->AddSpace( -1, 8, 0 ) if ($^O eq 'linux');
    $sizer->Add( $frame->{editpanel} ,  1 , wxGROW , 0) ;

