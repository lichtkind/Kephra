use v5.12;
use warnings;

package Kephra::App::Editor;
our @ISA = 'Wx::StyledTextCtrl';
use Wx qw/ :everything /;
use Wx::STC;
use Wx::DND;
#use Wx::Scintilla;
use Kephra::App::Editor::SyntaxMode;
use Kephra::App::Editor::Edit;
use Kephra::App::Editor::MoveText;
use Kephra::App::Editor::Tool;

sub new {
    my( $class, $parent, $style) = @_;
    my $self = $class->SUPER::new( $parent, -1,[-1,-1],[-1,-1] );
    $self->{'tab_size'} = 4;
    $self->{'tab_space'} = ' ' x $self->{'tab_size'};
    $self->SetWordChars('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._$@%&\\');
    #$self->BraceHighlightIndicator( 1, 1);
    $self->SetScrollWidth(300);
    Kephra::App::Editor::SyntaxMode::apply( $self );
    $self->mount_events();
    return $self;
}

sub mount_events {
    my ($self, @which) = @_;
    $self->DragAcceptFiles(1) if $^O eq 'MSWin32'; # enable drop files on win
    #$self->SetDropTarget( Kephra::App::Editor::TextDropTarget->new($self) );

    # Wx::Event::EVT_KEY_UP( $self, sub { my ($ed, $event) = @_; my $code = $event->GetKeyCode;  my $mod = $event->GetModifiers; });
    Wx::Event::EVT_KEY_DOWN( $self, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode; # my $raw = $event->GetRawKeyCode;
        my $mod = $event->GetModifiers; #
        if (($mod == 1 or $mod == 3) and $code == 81)    { $ed->insert_text('@') } # Q
        elsif ( $event->ControlDown){
            if ($event->AltDown) {$event->Skip
            } else {
                if ($event->ShiftDown){
                    if    ($code == 65)                { $ed->shrink_selecton   } # A
                    elsif ($code == &Wx::WXK_UP)       { $ed->select_prev_block }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->select_next_block }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->select_prev_sub   }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->select_next_sub   }
                    else                               { $event->Skip           }
                } else {
                    if    ($code == 65)                { $ed->expand_selecton   } # A
                    elsif ($code == 67)                { Kephra::App::Editor::Edit::copy( $ed )  } # C
                    elsif ($code == 76)                { $ed->sel               } # L
                    elsif ($code == 88)                { Kephra::App::Editor::Edit::cut( $ed )   } # X
                    elsif ($code == &Wx::WXK_UP)       { $ed->goto_prev_block   }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->goto_next_block   }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->goto_prev_sub     }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->goto_next_sub     }
                    else                               { $event->Skip }
                }
            }
        } else {
            if ($event->AltDown) {
                if ($event->ShiftDown){
                    if    ($code == &Wx::WXK_UP)       {  }
                    elsif ($code == &Wx::WXK_DOWN)     {  }
                    elsif ($code == &Wx::WXK_LEFT)     {  }
                    elsif ($code == &Wx::WXK_RIGHT)    {  }
                    else                               { $event->Skip }
                } else {
                    #elsif ($code == &Wx::WXK_UP)      { Kephra::App::Editor::MoveText::up( $ed )     }
                    #elsif ($code == &Wx::WXK_DOWN)    { Kephra::App::Editor::MoveText::down( $ed )   }
                    #elsif ($code == &Wx::WXK_LEFT)    { Kephra::App::Editor::MoveText::left( $ed )   }
                    #elsif ($code == &Wx::WXK_RIGHT)   { Kephra::App::Editor::MoveText::right( $ed )  }
                    if    ($code == &Wx::WXK_PAGEUP)   { Kephra::App::Editor::MoveText::page_up($ed)  }
                    elsif ($code == &Wx::WXK_PAGEDOWN) { Kephra::App::Editor::MoveText::page_down($ed)}
                    elsif ($code == &Wx::WXK_HOME)     { Kephra::App::Editor::MoveText::start( $ed )  }
                    elsif ($code == &Wx::WXK_END )     { Kephra::App::Editor::MoveText::end( $ed )    }
                    else                               { $event->Skip }
                }
            } else { 
                if ($code == &Wx::WXK_F11)             { $self->GetParent->ShowFullScreen( not $self->GetParent->IsFullScreen ) }
                else                                   { $event->Skip }
            }
        }    
    });
  
    # Wx::Event::EVT_LEFT_DOWN( $self, sub {});
    # Wx::Event::EVT_RIGHT_DOWN( $self, sub {});
    # Wx::Event::EVT_MIDDLE_UP( $self, sub { say 'right';  $_[1]->Skip;  });
 
    Wx::Event::EVT_STC_CHARADDED( $self, $self, sub {  });
    Wx::Event::EVT_STC_CHANGE ( $self, -1, sub {
        my ($ed, $event) = @_;
        $ed->{'change_pos'} = $ed->GetCurrentPos; # say 'skip';
        if ($self->SelectionIsRectangle){
            #say $event;
        } else { $event->Skip }
    });
    
    Wx::Event::EVT_STC_UPDATEUI(         $self, -1, sub {
        my $p = $self->GetCurrentPos;
        my $psrt = $self->GetCurrentLine.':'.$self->GetColumn( $p );
        my ($start_pos, $end_pos) = $self->GetSelection;
        $self->bracelight( $p );
        $psrt .= ' ('.($end_pos - $start_pos).')' if $start_pos != $end_pos;
        $self->GetParent->SetStatusText( $psrt , 0); # say 'ui';
#        delete $self->{'sel_head'} if exists $self->{'sel_head'} 
#                                         and $self->{'sel_head'} != $self->GetSelectionStart()
#                                         and $self->{'sel_head'} != $self->GetSelectionEnd(); 
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
    # Wx::Event::EVT_STC_START_DRAG   ($ep, -1, sub {
    # Wx::Event::EVT_STC_DRAG_OVER    ($ep, -1, sub { $droppos = $_[1]->GetPosition });
}

#say $self->GetRect;
# ->SelectionIsRectangle
# ->LineDownRectExtend
# ->LineUpRectExtend
# ->LineLeftRectExtend
# ->HomeRectExtend ()
# ->VCHomeRectExtend 
# ->SetInsertionPoint
# ->GetMultipleSelection
# ->GetRectangularSelectionAnchor()
# ->GetRectangularSelectionCaret()

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

sub is_empty { not $_[0]->GetTextLength }

sub new_text {
    my ($self, $content, $soft) = @_;
    return unless defined $content;
    $self->SetText( $content );
    $self->EmptyUndoBuffer unless defined $soft;
    $self->SetSavePoint;
}

sub insert_text {
    my ($self, $text, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->InsertText($pos, $text);
    $pos += length $text;
    $self->SetSelection( $pos, $pos );
}

sub sel {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
}

sub goto_last_edit { $_[0]->GotoPos( $_[0]->{'change_pos'}+1 ) }

sub goto_prev_block {
    my ($self) = @_;
    $self->GotoPos( $self->smart_up_pos );
    $self->EnsureCaretVisible;
}

sub goto_next_block {
    my ($self) = @_;
    $self->GotoPos( $self->smart_down_pos );
    $self->EnsureCaretVisible;
}

sub smart_up_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $bpos = $self->prev_brace_pos( $pos );
    return $bpos if $bpos != $pos;
    my $line_nr = $self->get_prev_block_start( $pos );
    defined $line_nr ? $self->PositionFromLine( $line_nr ) : $pos;
}

sub smart_down_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $bpos = $self->next_brace_pos( $pos );
    return $bpos if $bpos != $pos;
    my $line_nr = $self->get_next_block_start( $pos );
    defined $line_nr ? $self->PositionFromLine( $line_nr ) : $pos;
}

sub prev_brace_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    if ( $char_before eq ')' or $char_before eq '}' or $char_before eq ']' ) {
        my $mpos = $self->BraceMatch( $pos - 1 );
        return $mpos if $mpos != &Wx::wxSTC_INVALID_POSITION;
    } elsif ($char_after eq ')' or $char_after eq '}' or $char_after eq ']'){
        my $mpos = $self->BraceMatch( $pos );
        return $mpos + 1 if $mpos != &Wx::wxSTC_INVALID_POSITION;
    }
    $pos;
}

sub next_brace_pos {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    if ( $char_before eq '(' or $char_before eq '{' or $char_before eq '[' ) {
        my $mpos = $self->BraceMatch( $pos - 1 );
        return $mpos if $mpos != &Wx::wxSTC_INVALID_POSITION;
    } elsif ($char_after eq '(' or $char_after eq '{' or $char_after eq '['){
        my $mpos = $self->BraceMatch( $pos );
        return $mpos + 1 if $mpos != &Wx::wxSTC_INVALID_POSITION;
    }
    $pos;
}

sub prev_sub_line_nr {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos-1 );
    $self->SearchAnchor;
    $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

sub next_sub_line_nr {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos+1 );
    $self->SearchAnchor;
    $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

sub goto_prev_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->prev_sub_line_nr;
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }
    
}
sub goto_next_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->next_sub_line_nr;
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }
}


sub select_prev_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $anchor = $self->GetAnchor;
    my $new_pos = $self->prev_sub_line_nr( $pos );
    if ($new_pos > -1) { $self->SetCurrentPos(  $new_pos ) }
    else               { $self->SetCurrentPos(  $pos ) }
    $self->SetAnchor( $anchor );
    $self->EnsureCaretVisible;
}
sub select_next_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $anchor = $self->GetAnchor;
    my $new_pos = $self->next_sub_line_nr( $pos );
    if ($new_pos > -1) { $self->SetCurrentPos(  $new_pos ) }
    else               { $self->SetCurrentPos(  $pos ) }
    $self->SetAnchor($anchor);
    $self->EnsureCaretVisible;
}

sub get_prev_block_start {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    return 0 if $line_nr == 0;
    unless ( $self->GetLine( --$line_nr ) =~ /\S/ ){
         while ($line_nr > 0){
             last if $self->GetLine( $line_nr ) =~ /\S/;
             $line_nr--;
    } }
    while ($line_nr > 0){
        last unless $self->GetLine( $line_nr - 1 ) =~ /\S/;
        $line_nr--;
    }
    $line_nr;    
}
sub get_next_block_start {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    my $last_line_nr = $self->GetLineCount - 1;
    return $line_nr if $line_nr == $last_line_nr;
    if ( $self->GetLine( ++$line_nr ) =~ /\S/ ){
         while ($line_nr < $last_line_nr){
             last unless $self->GetLine( ++$line_nr ) =~ /\S/;
    } }
    while ($line_nr < $last_line_nr){
        last if $self->GetLine( ++$line_nr ) =~ /\S/;
    }
    $line_nr;
}
sub get_prev_block_end {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    return 0 if $line_nr == 0;
    if ( $self->GetLine( --$line_nr ) =~ /\S/ ){
         while ($line_nr > 0){
             last unless $self->GetLine( --$line_nr ) =~ /\S/;
    } }
    while ($line_nr > 0){
        last if $self->GetLine( --$line_nr ) =~ /\S/;
    }
    $line_nr;
}
sub get_next_block_end {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    my $last_line_nr = $self->GetLineCount - 1;
    return $line_nr if $line_nr == $last_line_nr;
    unless ( $self->GetLine( ++$line_nr ) =~ /\S/ ){
         while ($line_nr < $last_line_nr){
             last if $self->GetLine( ++$line_nr ) =~ /\S/;
    } }
    while ($line_nr < $last_line_nr){
        last unless $self->GetLine( $line_nr + 1 ) =~ /\S/;
        $line_nr++;
    }
    $line_nr;
}

# # [\w\.\\\$@%&]
sub select_prev_block {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $anchor = $self->GetAnchor;
    my $bpos = $self->prev_brace_pos( $pos );
    my $new_pos;
    if ($bpos != $pos) { $new_pos = $bpos }
    else {
        if ($pos <= $anchor) { $new_pos = $self->PositionFromLine( $self->get_prev_block_start( $pos ) ) }
        else                 { $new_pos = $self->GetLineEndPosition( $self->get_prev_block_end( $pos ) );
                               $new_pos = $self->PositionFromLine( $self->get_prev_block_start( $pos ) ) if $new_pos < $anchor;
        }
    }
    $new_pos = 0 if $new_pos < 0;
    $self->SetCurrentPos( $new_pos );
    $self->SetAnchor($anchor);
    $self->EnsureCaretVisible;
}
sub select_next_block {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $anchor = $self->GetAnchor;
    my $bpos = $self->next_brace_pos( $pos );
    my $new_pos;
    if ($bpos != $pos) { $new_pos = $bpos }
    else {
        if ($pos >= $anchor) { $new_pos = $self->GetLineEndPosition( $self->get_next_block_end( $pos ) )  } 
        else                 { $new_pos = $self->PositionFromLine( $self->get_next_block_start( $pos ) );
                               $new_pos = $self->GetLineEndPosition( $self->get_next_block_end( $pos ) ) if $new_pos > $anchor;
        }
    }
    $self->SetCurrentPos( $new_pos );
    $self->SetAnchor($anchor);
    $self->EnsureCaretVisible;
}

sub expand_selecton {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );

    if ($start_line == $end_line) {
        if ($start_pos == $end_pos){
            $self->WordLeft;
            $self->WordRightExtend;
        } else {
        }
    } else {
        
    }
    
}

sub shrink_selecton {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    return if $start_pos == $end_pos;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );
    
}

1;
