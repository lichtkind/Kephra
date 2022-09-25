use v5.12;
use warnings;

# move line /page / block
# rect edit 
# copy word
# rot select
# auto indent

package Kephra::App::Editor;
our @ISA = 'Wx::StyledTextCtrl';
use Wx qw/ :everything /;
use Wx::STC;
use Wx::DND;
#use Wx::Scintilla;
use Kephra::App::Editor::SyntaxMode;
use Kephra::App::Editor::MoveText;

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
        my $mod = $event->GetModifiers; #
        if (($mod == 1 or $mod == 3) and $code == ord('Q'))    { $ed->insert_text('@') }
        elsif ( $event->ControlDown){
            if ($event->AltDown) {$event->Skip
            } else {
                if ($event->ShiftDown){
                    if   ($code == &Wx::WXK_UP)        { $ed->select_prev_block  }
                    elsif($code == &Wx::WXK_DOWN)      { $ed->select_next_block  }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->select_prev_sub   }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->select_next_sub   }
                    else                               { $event->Skip }
                } else {
                    if    ($code == ord('C'))          { $ed->copy()  }
                    elsif ($code == ord('X'))          { $ed->cut()   }
                  # elsif ($code == ord('L'))          { }
                    elsif ($code == &Wx::WXK_UP)       { $ed->goto_prev_block }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->goto_next_block }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->goto_prev_sub   }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->goto_next_sub   }
                    else                               { $event->Skip }
                }
            }
        } else {
            if ($event->AltDown) {
                if ($event->ShiftDown){ 
                    if    ($code == &Wx::WXK_UP)      {  }
                    elsif ($code == &Wx::WXK_DOWN)    {  }
                    elsif ($code == &Wx::WXK_LEFT)    {  }
                    elsif ($code == &Wx::WXK_RIGHT)   {  }
                    else                              { $event->Skip }
                } else {
                    if    ($code == &Wx::WXK_UP)      { Kephra::App::Editor::MoveText::up( $ed )     }
                    elsif ($code == &Wx::WXK_DOWN)    { Kephra::App::Editor::MoveText::down( $ed )   }
                    elsif ($code == &Wx::WXK_LEFT)    { Kephra::App::Editor::MoveText::left( $ed )   }
                    elsif ($code == &Wx::WXK_RIGHT)   { Kephra::App::Editor::MoveText::right( $ed )  }
                    elsif ($code == &Wx::WXK_PAGEUP)  { Kephra::App::Editor::MoveText::page_up($ed)  }
                    elsif ($code == &Wx::WXK_PAGEDOWN){ Kephra::App::Editor::MoveText::page_down($ed)}
                    elsif ($code == &Wx::WXK_HOME)    { Kephra::App::Editor::MoveText::start( $ed )  }
                    elsif ($code == &Wx::WXK_END )    { Kephra::App::Editor::MoveText::end( $ed )    }
                    else                              { $event->Skip }
                }
            } else { $event->Skip }
        }    
    });


    # Wx::Event::EVT_KEY_UP( $self, sub { my ($ed, $event) = @_; my $code = $event->GetKeyCode;  my $mod = $event->GetModifiers; });
    Wx::Event::EVT_STC_CHARADDED( $self, $self, sub {  });
    
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


# ->SelectionIsRectangle
# ->LineDownRectExtend
# ->LineUpRectExtend
# ->LineLeftRectExtend
# ->HomeRectExtend ()
# ->VCHomeRectExtend 


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

sub prev_sub_line_nr {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    $self->GotoPos( $pos-1 );
    $self->SearchAnchor;
    $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '^sub ');
}

sub next_sub_line_nr {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    $self->GotoPos( $pos+1 );
    $self->SearchAnchor;
    $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '^sub ');
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
    my ($start, $end) = $self->GetSelection;
    my $new_pos = $self->prev_sub_line_nr;
    if ($new_pos > -1) { $self->SetSelection( $new_pos, $end ) }
    else               { $self->SetSelection( $start,   $end ) }
    $self->EnsureCaretVisible();
}

sub select_next_sub {
    my ($self) = @_;
    my ($start, $end) = $self->GetSelection;
    my $new_pos = $self->next_sub_line_nr;
    if ($new_pos > -1) { $self->SetSelection( $start, $new_pos ) }
    else               { $self->SetSelection( $start, $end     ) }
    $self->EnsureCaretVisible();
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
    $self->GetSelectedText( ) =~ /^(\s*)((?:#\s)|(?:#~\s))?(.*)$/;
    return unless $3;
    $2 ? $self->ReplaceSelection( $1. $3 ) 
       : $self->ReplaceSelection( $1.'# '.$3 );
}

sub toggle_block_comment_line {
    my ($self, $line_nr) = @_;
    return unless defined $line_nr;
    $self->SetSelection( $self->PositionFromLine( $line_nr ),
                         $self->GetLineEndPosition( $line_nr )  );
    $self->GetSelectedText( ) =~ /^(\s*)(#?)(~\s)?(.*)$/;
    return if (not $4) or ($2 and not $3);
    $2 ? $self->ReplaceSelection( $1. $4     ) 
       : $self->ReplaceSelection( $1.'#~ '.$4 );
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

sub toggle_block_comment {
    my ($self) = @_;
    my ($old_start, $old_end) = $self->GetSelection;
    $self->BeginUndoAction();

    $self->toggle_block_comment_line( $_ ) for $self->LineFromPosition( $old_start ) ..
                                               $self->LineFromPosition( $old_end );
    $self->GotoPos( $old_end );
    $self->EndUndoAction();
}


1;
