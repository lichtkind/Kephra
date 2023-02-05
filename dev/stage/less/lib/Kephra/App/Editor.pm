use v5.12;
use warnings;

package Kephra::App::Editor;
our @ISA = 'Wx::StyledTextCtrl';
use Wx qw/ :everything /;
use Wx::STC;
use Wx::DND;
#use Wx::Scintilla;
use Kephra::App::Editor::Edit;
use Kephra::App::Editor::Goto;
use Kephra::App::Editor::Move;
use Kephra::App::Editor::Position;
use Kephra::App::Editor::Property;
use Kephra::App::Editor::Select;
use Kephra::App::Editor::SyntaxMode;
use Kephra::App::Editor::Tool;
use Kephra::App::Editor::View;

sub new {
    my( $class, $parent, $style) = @_;
    my $self = $class->SUPER::new( $parent, -1,[-1,-1],[-1,-1] );
    $self->{'tab_size'} = 4;
    $self->{'tab_space'} = ' ' x $self->{'tab_size'};
    $self->SetWordChars('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._$@%&*\\');
    $self->SetAdditionalCaretsBlink( 1 );
    $self->SetAdditionalCaretsVisible( 1 );
    $self->SetAdditionalSelectionTyping( 1 );
    $self->SetIndentationGuides( 2 );  # wxSTC_WS_VISIBLEAFTERINDENT   2   wxSTC_WS_VISIBLEALWAYS 1
    # $self->SetAdditionalSelAlpha( 1 );
    $self->SetScrollWidth(300);
    $self->set_margin;
    $self->load_font;  # before setting highlighting
    Kephra::App::Editor::SyntaxMode::apply( $self, 'perl' );
    $self->set_tab_size( $self->{'tab_size'} );
    $self->set_tab_usage( 0 );
    $self->mount_events();
    $self->{'change_pos'} = $self->{'change_prev'} = -1;
    return $self;
}

sub apply_config {
    my ($self, $config) = @_;
    my $config_value = $config->get_value('editor');
    $self->{ $_ } = $config_value->{ $_ } for qw/change_pos change_prev/;
    $self->init_marker( @{$config_value->{'marker'}} );
    $self->SetSelection( $config_value->{'cursor_pos'}, $config_value->{'cursor_pos'});
    $self->EnsureCaretVisible;
}

sub save_config {
    my ($self, $config) = @_;
    $config->set_value( { change_pos => $self->{'change_pos'},
                          change_prev => $self->{'change_prev'},
                          cursor_pos => $self->GetCurrentPos,
                          marker => [ $self->marker_lines ],
                        } , 'editor');
}

sub set_margin {
    my ($self, $style) = @_;

    if (not defined $style or not $style or $style eq 'default') {
        $self->SetMarginType( 0, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginType( 1, &Wx::wxSTC_MARGIN_NUMBER );
        $self->SetMarginType( 2, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginType( 3, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginMask( 0, 0x01FFFFFF );
        $self->SetMarginMask( 1, 0 );
        $self->SetMarginMask( 2, 0x01FFFFFF); #  | &Wx::wxSTC_MASK_FOLDERS
        $self->SetMarginMask( 3, &Wx::wxSTC_MASK_FOLDERS );
        $self->SetMarginSensitive( 0, 1 );
        $self->SetMarginSensitive( 1, 1 );
        $self->SetMarginSensitive( 2, 1 );
        $self->SetMarginSensitive( 3, 0 );
        $self->SetMarginWidth(0,  1);
        $self->SetMarginWidth(1, 47);
        $self->SetMarginWidth(2, 22);
        $self->SetMarginWidth(3,  2);
        # extra text margin
    }
    elsif ($style eq 'no') { $self->SetMarginWidth($_, 0) for 1..3 }

    # extra margin left and right inside the white text area
    $self->SetMargins(2, 2);
    $self;
}

sub load_font {
    my ($self, $font) = @_;
    my ( $fontweight, $fontstyle ) = ( &Wx::wxNORMAL, &Wx::wxNORMAL );
    $font = {
        family => $^O eq 'darwin' ? 'Andale Mono' : 'Courier New', # old default
                # Courier New
        #family => 'DejaVu Sans Mono', # new
        size => $^O eq 'darwin' ? 13 : 11,
        style => 'normal',
        weight => 'normal',
    } unless defined $font;
    #my $font = _config()->{font};
    $fontweight = &Wx::wxLIGHT  if $font->{weight} eq 'light';
    $fontweight = &Wx::wxBOLD   if $font->{weight} eq 'bold';
    $fontstyle  = &Wx::wxSLANT  if $font->{style}  eq 'slant';
    $fontstyle  = &Wx::wxITALIC if $font->{style}  eq 'italic';
    my $wx_font = Wx::Font->new(
        $font->{size}, &Wx::wxDEFAULT, $fontstyle, $fontweight, 0, $font->{family}
    );
    $self->StyleSetFont( &Wx::wxSTC_STYLE_DEFAULT, $wx_font ) if $wx_font->Ok > 0;
}


sub mount_events {
    my ($self, @which) = @_;
    $self->DragAcceptFiles(1) if $^O eq 'MSWin32'; # enable drop files on win
    #$self->SetDropTarget( Kephra::App::Editor::TextDropTarget->new($self) );

    # Wx::Event::EVT_KEY_UP( $self, sub { my ($ed, $event) = @_; my $code = $event->GetKeyCode;  my $mod = $event->GetModifiers; });
    Wx::Event::EVT_KEY_DOWN( $self, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode; # my $raw = $event->GetRawKeyCode;
        my $mod = $event->GetModifiers; #  say $code;
        #   alt ",$event->AltDown, " ; ctrl ",$event->ControlDown; say "mod $mod code $code";

        if ( $event->ControlDown and $mod != 3) { # $mod == 2 and
            if ($event->AltDown) {
                $event->Skip
            } else {
                if ($event->ShiftDown){
                    #if    ($code == 65)                { $ed->shrink_selecton   } # A
                    if    ($code == &Wx::WXK_UP)       { $ed->select_prev_block }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->select_next_block }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->select_prev_sub   }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->select_next_sub   }
                    else                               { $event->Skip           }
                } else {
                    if    ($code == 43 or $code == 388){ $ed->zoom_in           } # +
                    elsif ($code == 45 or $code == 390){ $ed->zoom_out          } # -
                    elsif ($code == 65)                { $ed->expand_selecton   } # A
                    elsif ($code == 67)                { $ed->copy              } # C
                    elsif ($code == 76)                { $ed->sel               } # L
                    elsif ($code == 88)                { $ed->cut               } # X
                    elsif ($code == &Wx::WXK_UP)       { $ed->goto_prev_block   }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->goto_next_block   }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->goto_prev_sub     }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->goto_next_sub     }
                    else                               { $event->Skip }
                }
            }
        } else {
            if ($mod == 3) { # Alt Gr
                if ($event->ShiftDown) {
                    $event->Skip
                } else {
                    if    ($code == 81)                    { $ed->insert_text('@') } # Q
                    elsif ($code == 55 )                   { $ed->insert_brace('{', '}') }
                    elsif ($code == 56 )                   { $ed->insert_brace('[', ']') }
                    else                                   { $event->Skip                }
                }
            } elsif ( $event->AltDown ) { # $mod == 1
                if ($event->ShiftDown){
                    if    ($code == &Wx::WXK_UP)       { $ed->select_rect_up    }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->select_rect_down  }
                    elsif ($code == &Wx::WXK_LEFT)     { $ed->select_rect_left  }
                    elsif ($code == &Wx::WXK_RIGHT)    { $ed->select_rect_right }
                    else                               { $event->Skip }
                } else {
                    if    ($code == &Wx::WXK_UP)       { $ed->move_up           }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->move_down         }
                    elsif ($code == &Wx::WXK_LEFT)     { $ed->move_left         }
                    elsif ($code == &Wx::WXK_RIGHT)    { $ed->move_right        }
                    elsif ($code == &Wx::WXK_PAGEUP)   { $ed->move_page_up      }
                    elsif ($code == &Wx::WXK_PAGEDOWN) { $ed->move_page_down    }
                    elsif ($code == &Wx::WXK_HOME)     { $ed->move_to_start     }
                    elsif ($code == &Wx::WXK_END )     { $ed->move_to_end       }
                    elsif ($code == &Wx::WXK_DELETE)   { $ed->delete_line       }
                    elsif ($code == 55 )               { $ed->insert_brace('{', '}') }
                    elsif ($code == 56 )               { $ed->insert_brace('[', ']') }
                    else                               { $event->Skip }
                }
            } else {
                if ($event->ShiftDown){
                    if    ($code == 35 )                   { $ed->insert_brace("'", "'") }
                    elsif ($code == 40 )                   { $ed->insert_brace('(', ')') }
                    elsif ($code == 50 )                   { $ed->insert_brace('"', '"') }
                    else                                   { $event->Skip                }
                } else {
                    if    ($code == &Wx::WXK_ESCAPE )      { $ed->escape                 }
                    elsif ($code == &Wx::WXK_RETURN)       { $self->new_line             }
                    else                                   { $event->Skip                }
                }
            }
        }
    });

    Wx::Event::EVT_LEFT_DOWN( $self, sub {
        my ($ed, $ev) = @_;
        #my $XY = $ev->GetLogicalPosition( Wx::MemoryDC->new( ) );
        #my $pos = $ed->XYToPosition( $XY->x, $XY->y);
        # $ed->expand_selecton( $pos ) or
        $ev->Skip;
    });
    # Wx::Event::EVT_RIGHT_DOWN( $self, sub {});
    Wx::Event::EVT_MIDDLE_UP( $self, sub {  $_[1]->Skip;  });

    # Wx::Event::EVT_STC_CHARADDED( $self, $self, sub {  });
    Wx::Event::EVT_STC_CHANGE ( $self, -1, sub {  # edit event
        my ($ed, $event) = @_;
        my $pos = $ed->GetCurrentPos;
        unless ($ed->{'change_pos'} == $pos) {
            $ed->{'change_prev'} = $ed->{'change_pos'};
            $ed->{'change_pos'} = $pos;
        }
        # if ($self->SelectionIsRectangle) { } else { }
        $event->Skip;
    });

    Wx::Event::EVT_STC_UPDATEUI(         $self, -1, sub { # cursor move event
        my ($ed, $event) = @_;
        my $p = $self->GetCurrentPos;
        my ($start_pos, $end_pos) = $self->GetSelection;
        $ed->{'set_pos'} = $p if $start_pos == $end_pos; # say "move ",$ed->{'set_pos'};
        $self->bracelight( $p );
        my $psrt = ($self->GetCurrentLine+1).':'.$self->GetColumn( $p );
        $psrt .= ' ('.($end_pos - $start_pos).')' if $start_pos != $end_pos;
        $self->GetParent->SetStatusText( $psrt , 0); # say 'ui';
    });
    Wx::Event::EVT_STC_SAVEPOINTREACHED( $self, -1, sub { $self->GetParent->set_title(0) });
    Wx::Event::EVT_STC_SAVEPOINTLEFT(    $self, -1, sub { $self->GetParent->set_title(1) });
    Wx::Event::EVT_SET_FOCUS(            $self,     sub { my ($ed, $event ) = @_;        $event->Skip;   });
    # Wx::Event::EVT_DROP_FILES       ($self, sub { say $_[0], $_[1];    $self->GetParent->open_file()  });
#    Wx::Event::EVT_STC_DO_DROP  ($self, -1, sub {
#        my ($ed, $event ) = @_; # StyledTextEvent=SCALAR
#        my $str = $event->GetDragText;
#        chomp $str;
#        if (substr( $str, 0, 7) eq 'file://'){
#            $self->GetParent->open_file( substr $str, 7 );
#        }
#        return; # $event->Skip;
#    });

}

sub is_empty { not $_[0]->GetTextLength }

sub new_text {
    my ($self, $content, $soft) = @_;
    return unless defined $content;
    $self->SetText( $content );
    $self->EmptyUndoBuffer unless defined $soft;
    $self->SetSavePoint;
}

sub bracelight{
    my ($self, $pos) = @_;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    if (    $char_before eq '(' or $char_before eq ')'
         or $char_before eq '{' or $char_before eq '}'
         or $char_before eq '[' or $char_before eq ']' ) {
        my $mpos = $self->BraceMatch( $pos - 1 );
        $mpos != &Wx::wxSTC_INVALID_POSITION
            ? $self->BraceHighlight($pos - 1, $mpos)
            : $self->BraceBadLight($pos - 1);
    } elsif ($char_after eq '(' or $char_after eq ')'
          or $char_after eq '{' or $char_after eq '}'
          or $char_after eq '[' or $char_after eq ']'){
        my $mpos = $self->BraceMatch( $pos );
        $mpos != &Wx::wxSTC_INVALID_POSITION
            ? $self->BraceHighlight($pos, $mpos)
            : $self->BraceBadLight($pos);
    } else  { $self->BraceHighlight(-1, -1); $self->BraceBadLight( -1 ) }
}

sub new_line {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    $self->NewLine;
    my $l = $self->GetCurrentLine;
    my $i = $self->GetLineIndentation( $l - 1 );

    if ($char_before eq '{' and $char_after eq '}'){ # postion braces when around caret
        $self->NewLine;
        $self->SetLineIndentation( $self->GetCurrentLine, $i );
        $i+= $self->{'tab_size'}
    } else {
        # ignore white space left of caret
        while ($char_before eq ' ' and $self->LineFromPosition( $pos ) == $l-1){
            $pos--;
            $char_before = $self->GetTextRange( $pos-1, $pos );
        }
        if ($char_before eq '{')    { $i+= $self->{'tab_size'} }
        elsif ($char_before eq '}') {
            my $mpos = $self->BraceMatch( $pos - 1 );
            if ($mpos != &Wx::wxSTC_INVALID_POSITION){
                $i = $self->GetLineIndentation( $self->LineFromPosition( $mpos ) );
            } else {
                $i-= $self->{'tab_size'};
                $i = 0 if $i < 0;
            }
        }
    }
    $self->SetLineIndentation( $l, $i );
    $self->GotoPos( $self->GetLineIndentPosition( $l ) );
}

sub escape {
    my ($self) = @_;
    #my ($start_pos, $end_pos) = $self->GetSelection;
    my $win = $self->GetParent;
    #if ($start_pos != $end_pos) { return $self->GotoPos ( $self->GetCurrentPos ) }
    if ($win->IsFullScreen) { return $win->toggle_full_screen};
    # 3. focus  to edit field
    #say 'esc';
}

sub sel {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    #say $self->GetStyleAt( $pos);
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



