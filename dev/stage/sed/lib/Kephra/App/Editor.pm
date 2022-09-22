use v5.12;
use warnings;

# move line /page / block
# rect edit, 
# rot select
# auto indent

package Kephra::App::Editor;
our @ISA = 'Wx::StyledTextCtrl';
use Wx qw/ :everything /;
use Wx::STC;
use Wx::DND;
#use Wx::Scintilla;
use Kephra::App::Editor::SyntaxMode;

sub new {
    my( $class, $parent, $style) = @_;
    my $self = $class->SUPER::new( $parent, -1,[-1,-1],[-1,-1] );
    $self->{'tab_size'} = 4;
    $self->{'tab_space'} = ' ' x $self->{'tab_size'};
    $self->SetScrollWidth(300);
    Kephra::App::Editor::SyntaxMode::apply( $self );
    $self->mount_events();
    return $self;
}

sub mount_events {
    my ($self, @which) = @_;
    $self->DragAcceptFiles(1) if $^O eq 'MSWin32'; # enable drop files on win
    #$self->SetDropTarget( Kephra::App::Editor::TextDropTarget->new($self) );

    Wx::Event::EVT_STC_CHANGE ( $self, -1, sub {
        my ($ed, $event) = @_;
        $ed->{'change_pos'} = $ed->GetCurrentPos; # say 'skip';
        if ($self->SelectionIsRectangle){
            #say $event;
        } else { $event->Skip }

    });

    Wx::Event::EVT_KEY_DOWN( $self, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode ; # my $raw = $event->GetRawKeyCode;
        my $mod = $event->GetModifiers; # say "$mod : ", $code, " ($raw) ",  &Wx::WXK_LEFT;
        if (($mod == 1 or $mod == 3) and $code == ord('Q'))    { $ed->insert_text('@') }
        elsif($event->ControlDown    and $code == ord('C'))    { $ed->copy()           }
        elsif($event->ControlDown    and $code == ord('X'))    { $ed->cut()            }
        elsif($event->ControlDown    and $code == ord('L'))    { }
        elsif($event->ControlDown and $event->ShiftDown and $code == &Wx::WXK_UP)   { $ed->select_prev_block  }
        elsif($event->ControlDown and $event->ShiftDown and $code == &Wx::WXK_DOWN) { $ed->select_next_block  }
        elsif($event->ControlDown and $code == &Wx::WXK_UP)       { $ed->goto_prev_block  }
        elsif($event->ControlDown and $code == &Wx::WXK_DOWN)     { $ed->goto_next_block  }
        elsif($event->ControlDown and $code == &Wx::WXK_PAGEUP )  { $ed->goto_prev_sub  }
        elsif($event->ControlDown and $code == &Wx::WXK_PAGEDOWN ){ $ed->goto_next_sub  }
        elsif($event->AltDown     and $event->ShiftDown and $code == &Wx::WXK_UP)       { $event->Skip  }
        elsif($event->AltDown     and $event->ShiftDown and $code == &Wx::WXK_DOWN)     { $event->Skip  }
        elsif($event->AltDown     and $event->ShiftDown and $code == &Wx::WXK_LEFT)     { $event->Skip  }
        elsif($event->AltDown     and $event->ShiftDown and $code == &Wx::WXK_RIGHT)    { $event->Skip  }
#        elsif($event->AltDown    and $event->ShiftDown and $code == &Wx::WXK_PAGEUP)   {   }
#        elsif($event->AltDown    and $event->ShiftDown and $code == &Wx::WXK_PAGEDOWN) {   }
        elsif($event->AltDown     and $code == &Wx::WXK_UP)    { $ed->move_text_up     }
        elsif($event->AltDown     and $code == &Wx::WXK_DOWN)  { $ed->move_text_down   }
        elsif($event->AltDown     and $code == &Wx::WXK_LEFT)  { $ed->move_text_left   }
        elsif($event->AltDown     and $code == &Wx::WXK_RIGHT) { $ed->move_text_right  }
        else {$event->Skip}
    });


    # Wx::Event::EVT_KEY_UP( $self, sub { my ($ed, $event) = @_; my $code = $event->GetKeyCode;  my $mod = $event->GetModifiers; });
    # Wx::Event::EVT_STC_CHARADDED( $self, $self, sub {});
    
    # Wx::Event::EVT_LEFT_DOWN( $self, sub {});
    # Wx::Event::EVT_RIGHT_DOWN( $self, sub {});
    # Wx::Event::EVT_MIDDLE_UP( $self, sub { say 'right';  $_[1]->Skip;  });
    
    Wx::Event::EVT_STC_UPDATEUI(         $self, -1, sub { 
        $self->GetParent->SetStatusText( $self->GetCurrentPos, 0); # say 'ui';
        delete $self->{'sel_head'} if exists $self->{'sel_head'} 
                                         and $self->{'sel_head'} != $self->GetSelectionStart()
                                         and $self->{'sel_head'} != $self->GetSelectionEnd(); 
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

sub is_empty { not shift->GetTextLength }

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

sub copy {
    my $self = shift;
    my ($start_pos, $end_pos) = $self->GetSelection;
    $start_pos == $end_pos ? $self->LineCopy : $self->Copy;
}

sub cut {
    my $self = shift;
    my ($start_pos, $end_pos) = $self->GetSelection;
    $start_pos == $end_pos ? $self->LineCut : $self->Cut;
}
    
sub replace {
    my $self = shift;
    my $sel = $self->GetSelectedText();
    return unless $sel;
    my ($old_start, $old_end) = $self->GetSelection;
    $self->BeginUndoAction();
    $self->SetSelectionEnd( $old_start );
    $self->Paste;
    my $new_start = $self->GetSelectionStart( );
    my $new_end = $self->GetSelectionEnd( );
    $self->SetSelection( $new_end, $new_end + $old_end - $old_start);
    $self->Cut;
    $self->SetSelection( $new_start, $new_end);
    $self->EndUndoAction();
}

sub move_text_up {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $self->PositionFromLine( $start_line );
    return unless $start_line; # need space above
    $self->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $self->LineTranspose;
        $self->GotoPos ( $self->PositionFromLine( $start_line - 1 ) + $start_col);
    } elsif ($start_line != $end_line) {
        my $end_col =  $end_pos - $self->PositionFromLine( $end_line );
        $self->move_line( $start_line - 1, $end_line);
        $self->SetSelection( $self->PositionFromLine( $start_line - 1 ) + $start_col,
                             $self->PositionFromLine( $end_line - 1 ) + $end_col );
    } else {}
    $self->EndUndoAction();
}

sub move_text_down {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $self->PositionFromLine( $start_line );
    my $end_col = $end_pos - $self->PositionFromLine( $end_line );
    $self->BeginUndoAction();
    if ( $end_line + 1 == $self->GetLineCount ) {
        $self->GotoLine( $start_line );
        $self->NewLine;
    } elsif ($start_pos == $end_pos) {
        $self->GotoLine( $start_line + 1 );
        $self->LineTranspose;
        $self->GotoPos ( $self->PositionFromLine( $start_line + 1 ) + $start_col);
    } elsif ($start_line != $end_line) {
        $self->move_line( $end_line + 1, $start_line);
    } else { return }
    $self->SetSelection( $self->PositionFromLine( $start_line + 1 ) + $start_col,
                         $self->PositionFromLine( $end_line + 1 ) + $end_col );
    $self->EndUndoAction();
}

sub move_line {
    my ($self, $from, $to) = @_;
    return unless defined $to and $from < $self->GetLineCount and $to < $self->GetLineCount;
    $from = $self->GetLineCount + $from if $from < 0;
    $to =   $self->GetLineCount + $to   if $to < 0;
    return if $from == $to;
    my $last_line_nr = $self->GetLineCount - 1;
    if ($from  == $last_line_nr) {
        $self->GotoLine( $from );
        $self->LineTranspose;
        $from--;
    }
    $self->SetSelection( $self->PositionFromLine( $from ),
                         $self->PositionFromLine( $from + 1 ) );
    my $line = $self->GetSelectedText( );
    $self->ReplaceSelection( '' );
    if ($to == $last_line_nr) {
        $self->InsertText( $self->PositionFromLine($to - 1), $line );
        $self->GotoLine( $to );
        $self->LineTranspose;
    } else { $self->InsertText( $self->PositionFromLine($to), $line ) }
}

sub move_line_left {
    my ($self, $line_nr) = @_;
    return unless defined $line_nr;
    $self->SetSelection( $self->PositionFromLine( $line_nr ),
                         $self->PositionFromLine( $line_nr ) + 1  );
    my $s = $self->GetSelectedText;
    $s = $self->{tab_space} if $s eq "\t";
    if (substr( $s, 0, 1 ) eq ' '){ chop $s }
    else                          { return 0 }
    $self->ReplaceSelection( $s );
    return 1;
}

sub move_line_right {
    my ($self, $line_nr) = @_;
    return unless defined $line_nr;
    $self->SetSelection( $self->PositionFromLine( $line_nr ),
                         $self->GetLineEndPosition( $line_nr )  );
    my $line = $self->GetSelectedText( );
    $line =~ s/\t/$self->{tab_space}/g if $line =~ /\t/;
    $self->ReplaceSelection( ' '.$line );
}

sub move_text_left {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );
    $self->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $start_pos-- if $self->move_line_left( $start_line );
        $self->GotoPos ( $start_pos );
    } elsif ($start_line != $end_line) {
        my $end_col = $end_pos - $self->PositionFromLine( $end_line );
        $start_pos-- if $self->move_line_left( $start_line );
        $end_col-- if $self->move_line_left( $end_line );
        $self->move_line_left( $_ ) for $start_line + 1 .. $end_line - 1;
        $self->SetSelection( $start_pos, $self->PositionFromLine( $end_line ) + $end_col );
    } else {}
    $self->EndUndoAction();
}

sub move_text_right {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );
    $self->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $self->move_line_right( $start_line );
        $self->GotoPos ( $start_pos + 1);
    } elsif ($start_line != $end_line) {
        $self->move_line_right( $_ ) for $start_line .. $end_line;
        $self->SetSelection( $start_pos + 1, $end_pos + 1 + $end_line -  $start_line);
    }  else {}
    $self->EndUndoAction();
}


sub goto_last_edit { $_[0]->GotoPos( $_[0]->{'change_pos'}+1 ) }

sub goto_prev_block {
    my ($self) = @_;
    my $line_nr = $self->get_prev_block_start( $self->GetSelectionStart );
    $self->GotoLine( $line_nr ) if defined $line_nr;
}

sub goto_next_block {
    my ($self) = @_;
    my $line_nr = $self->get_next_block_start( $self->GetSelectionEnd );
    $self->GotoLine( $line_nr ) if defined $line_nr;
}

sub goto_prev_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    $self->GotoPos( $pos-1 );
    $self->SearchAnchor;
    my $new_pos = $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '^sub ');
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }
}
sub goto_next_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    $self->GotoPos( $pos+1 );
    $self->SearchAnchor;
    my $new_pos = $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '^sub ');
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }
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


sub select_prev_block {
    my ($self) = @_;
    my ($start, $end) = $self->GetSelection;
    $self->{'sel_head'} = $start unless exists $self->{'sel_head'};
    if ($self->{'sel_head'} == $start) {
        my $line = $self->get_prev_block_start( $start );
        $self->{'sel_head'} = $start = $self->PositionFromLine( $line );
    } else {
        my $line = $self->get_prev_block_end( $end );
        $end = $self->GetLineEndPosition( $line ); 
        if ($end < $start) {
            my $line = $self->get_prev_block_start( $self->{'sel_head'} );
            $self->{'sel_head'} = $end = $self->PositionFromLine( $line );
            ($start, $end) = ($end, $start);
        } else { $self->{'sel_head'} = $end }
        
    }
    $self->GotoPos( $self->{'sel_head'} );
    $self->EnsureCaretVisible();
    $self->SetSelection( $start, $end );
}

sub select_next_block {
    my ($self) = @_;
    my ($start, $end) = $self->GetSelection;
    $self->{'sel_head'} = $end unless exists $self->{'sel_head'};
    if ($self->{'sel_head'} == $end) {
        my $line = $self->get_next_block_end( $end );
        $self->{'sel_head'} = $end = $self->GetLineEndPosition( $line );
    } else {
        my $line = $self->get_next_block_start( $start );
        $start = $self->PositionFromLine( $line ); 
        if ($end < $start) {
            my $line = $self->get_next_block_end( $self->{'sel_head'} );
            $self->{'sel_head'} = $start = $self->GetLineEndPosition( $line );
            ($start, $end) = ($end, $start);
        } else {$self->{'sel_head'} = $start }
    }
    $self->GotoPos( $self->{'sel_head'} );
    $self->EnsureCaretVisible();
    $self->SetSelection( $start, $end );
}


sub toggle_comment_line {
    my ($self, $line_nr) = @_;
    return unless defined $line_nr;
    $self->SetSelection( $self->PositionFromLine( $line_nr ),
                         $self->GetLineEndPosition( $line_nr )  );
    $self->GetSelectedText( ) =~ /^(\s*)(#\s+)?(.*)$/;
    return unless $3;
    $2 ? $self->ReplaceSelection( $1. $3     ) 
       : $self->ReplaceSelection( $1.'# '.$3 );
}
sub toggle_comment {
    my ($self) = @_;
    my ($old_start, $old_end) = $self->GetSelection;
    $self->BeginUndoAction();

    $self->toggle_comment_line( $_ ) for $self->LineFromPosition( $old_start ) ..
                                         $self->LineFromPosition( $old_end );
    $self->GotoPos( $old_end );
    $self->EndUndoAction();
}


1;
