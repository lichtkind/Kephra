use v5.12;
use warnings;

package Kephra::App::Editor::SyntaxMode;
use Wx qw/ :everything /;
use Wx::STC;
#use Wx::Scintilla;

sub apply {
    my ($self) = @_;
    set( $self, 'perl' );
    set_colors( $self ); # after highlight
}

sub set_colors {
    my $self = shift;
    $self->SetCaretPeriod( 600 );
    $self->SetCaretForeground( create_color( 0, 0, 100) ); #140, 160, 255
    $self->SetCaretLineBack( create_color(230, 230, 250) );
    $self->SetCaretWidth( 2 );
    $self->SetCaretLineVisible(1);

    $self->SetSelForeground( 1, create_color(243,243,243) );
    $self->SetSelBackground( 1, create_color(0, 17, 119) );
    $self->SetWhitespaceForeground( 1, create_color(200, 200, 153) );
    $self->SetViewWhiteSpace(1);

    $self->StyleSetForeground(&Wx::wxSTC_STYLE_INDENTGUIDE, create_color(206,206,202)); # 37
    $self->StyleSetForeground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(93,93,97));    # 33
    $self->StyleSetBackground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(206,206,202));

    $self->SetEdgeColour( create_color(200,200,255) );
    $self->SetEdgeColumn( 80 );
    $self->SetEdgeMode( &Wx::wxSTC_EDGE_LINE );
}
sub create_color { Wx::Colour->new(@_) }

sub set {
    my ($self, $mode) = @_;
    $mode //= 'no';
    if ($mode eq 'perl'){
        require Kephra::App::Editor::SyntaxMode::Perl;
        Kephra::App::Editor::SyntaxMode::Perl::set($self);
    } elsif ($mode eq 'no'){
        require Kephra::App::Editor::SyntaxMode::No;
        Kephra::App::Editor::SyntaxMode::No::set($self);
    }
}

1;

__END__

$self->SetIndicatorCurrent( $c);
$self->IndicatorFillRange( $start, $len );
$self->IndicatorClearRange( 0, $len )
#Wx::Event::EVT_STC_STYLENEEDED($self, sub{})
#Wx::Event::EVT_STC_CHARADDED($self, sub {});
#Wx::Event::EVT_STC_ROMODIFYATTEMPT($self, sub{})
#Wx::Event::EVT_STC_KEY($self, sub{})
#Wx::Event::EVT_STC_DOUBLECLICK($self, sub{})
Wx::Event::EVT_STC_UPDATEUI($self, -1, sub {
#my ($ed, $event) = @_; $event->Skip; print "change \n";
});
#Wx::Event::EVT_STC_MODIFIED($self, sub {});
#Wx::Event::EVT_STC_MACRORECORD($self, sub{})
#Wx::Event::EVT_STC_MARGINCLICK($self, sub{})
#Wx::Event::EVT_STC_NEEDSHOWN($self, sub {});
#Wx::Event::EVT_STC_PAINTED($self, sub{})
#Wx::Event::EVT_STC_USERLISTSELECTION($self, sub{})
#Wx::Event::EVT_STC_UR$selfROPPED($self, sub {});
#Wx::Event::EVT_STC_DWELLSTART($self, sub{})
#Wx::Event::EVT_STC_DWELLEND($self, sub{})
#Wx::Event::EVT_STC_START_DRAG($self, sub{})
#Wx::Event::EVT_STC_DRAG_OVER($self, sub{})
#Wx::Event::EVT_STC_DO_DROP($self, sub {});
#Wx::Event::EVT_STC_ZOOM($self, sub{})
#Wx::Event::EVT_STC_HOTSPOT_CLICK($self, sub{})
#Wx::Event::EVT_STC_HOTSPOT_DCLICK($self, sub{})
#Wx::Event::EVT_STC_CALLTIP_CLICK($self, sub{})
#Wx::Event::EVT_STC_AUTOCOMP_SELECTION($self, sub{})
#$self->SetAcceleratorTable( Wx::AcceleratorTable->new() );
#Wx::Event::EVT_STC_SAVEPOINTREACHED($self, -1, \&Kephra::File::savepoint_reached);
#Wx::Event::EVT_STC_SAVEPOINTLEFT($self, -1, \&Kephra::File::savepoint_left);
$self->SetAcceleratorTable(
Wx::AcceleratorTable->new(
[&Wx::wxACCEL_CTRL, ord 'n', 1000],
));



