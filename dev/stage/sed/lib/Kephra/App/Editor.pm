use v5.12;
use warnings;

# comment, rect edit, move line goto block

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
    Kephra::App::Editor::SyntaxMode::apply( $self );  # before setting highlighting
    $self->SetScrollWidth(300);
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
        $event->Skip;
    });

    Wx::Event::EVT_KEY_DOWN( $self, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode ; # my $raw = $event->GetRawKeyCode;
        my $mod = $event->GetModifiers; # say "$mod : ", $code, " ($raw) ",  &Wx::WXK_LEFT;
        if (($mod == 1 or $mod == 3) and $code == ord('Q'))    { $ed->insert_text('@') }
        elsif($event->ControlDown and $event->ShiftDown and $code == &Wx::WXK_UP)   { $ed->select_prev_block  }
        elsif($event->ControlDown and $event->ShiftDown and $code == &Wx::WXK_DOWN) { $ed->select_next_block  }
        elsif($event->ControlDown and $code == &Wx::WXK_UP)    { $ed->goto_prev_block  }
        elsif($event->ControlDown and $code == &Wx::WXK_DOWN)  { $ed->goto_next_block  }
#        elsif($event->AltDown and $code == &Wx::WXK_PAGEUP )  {   }
#        elsif($event->AltDown and $code == &Wx::WXK_PAGEDOWN ){   }
#        elsif($event->AltDown and $event->ShiftDown and $code == &Wx::WXK_UP)       {   }
#        elsif($event->AltDown and $event->ShiftDown and $code == &Wx::WXK_DOWN)     {   }
#        elsif($event->AltDown and $event->ShiftDown and $code == &Wx::WXK_DOWN)     {   }
#        elsif($event->AltDown and $event->ShiftDown and $code == &Wx::WXK_LEFT)     {   }
#        elsif($event->AltDown and $event->ShiftDown and $code == &Wx::WXK_RIGHT)    {   }
#        elsif($event->AltDown and $event->ShiftDown and $code == &Wx::WXK_PAGEUP)   {   }
#        elsif($event->AltDown and $event->ShiftDown and $code == &Wx::WXK_PAGEDOWN) {   }
#        elsif($event->ControlDown and $code == ord('K'))    {   }
        elsif($event->AltDown     and $code == &Wx::WXK_UP)    { $ed->move_text_up     }
        elsif($event->AltDown     and $code == &Wx::WXK_DOWN)  { $ed->move_text_down   }
        elsif($event->AltDown     and $code == &Wx::WXK_LEFT)  { $ed->move_text_left   }
        elsif($event->AltDown     and $code == &Wx::WXK_RIGHT) { $ed->move_text_right  }
        else { $event->Skip }
    });

    Wx::Event::EVT_KEY_UP( $self, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode;
        my $mod = $event->GetModifiers;
    });
    
    Wx::Event::EVT_STC_UPDATEUI(         $self, -1, sub { 
        $self->GetParent->SetStatusText( $self->GetCurrentPos, 0); # say 'ui';
        delete $self->{'sel_head'} if exists $self->{'sel_head'} 
                                         and $self->{'sel_head'} != $self->GetSelectionStart()
                                         and $self->{'sel_head'} != $self->GetSelectionEnd(); 
    });
    Wx::Event::EVT_STC_SAVEPOINTREACHED( $self, -1, sub { $self->GetParent->set_title(0) });
    Wx::Event::EVT_STC_SAVEPOINTLEFT(    $self, -1, sub { $self->GetParent->set_title(1) });
    Wx::Event::EVT_SET_FOCUS(            $self,     sub { my ($ed, $event ) = @_;        $event->Skip;   });
    Wx::Event::EVT_DROP_FILES       ($self, sub { 
         #say $_[0], $_[1];    #$self->GetParent->open_file()  
    });
    Wx::Event::EVT_STC_DO_DROP  ($self, -1, sub { 
        my ($ed, $event ) = @_; # StyledTextEvent=SCALAR
        my $str = $event->GetDragText;
        chomp $str;
        if (substr( $str, 0, 7) eq 'file://'){
            $self->GetParent->open_file( substr $str, 7 );
        }
        return; # $event->Skip;
    });
    # Wx::Event::EVT_STC_START_DRAG   ($ep, -1, sub {
    # Wx::Event::EVT_STC_DRAG_OVER    ($ep, -1, sub { $droppos = $_[1]->GetPosition });
}

sub is_empty { not shift->GetTextLength }

sub new_file { 
    my $self = shift;
    $self->GetParent->{'file'} = '';
    $self->ClearAll;
    $self->SetSavePoint;
}

sub open_file   { $_[0]->GetParent->open_file( Kephra::App::Dialog::get_file_open() ) }
sub reopen_file { $_[0]->GetParent->open_file( $_[0]->GetParent->{'file'} ) }
sub save_file {
    my $self = shift;
    $self->GetParent->{'file'} = Kephra::App::Dialog::get_file_save() unless $self->GetParent->{'file'};
    Kephra::IO::LocalFile::write( $self->GetParent->{'file'},  $self->GetParent->{'encoding'}, $self->GetText() );
    $self->SetSavePoint;
}
sub save_as_file {
    my $self = shift;
    $self->GetParent->{'file'} = Kephra::App::Dialog::get_file_save();
    Kephra::IO::LocalFile::write( $self->GetParent->{'file'},  $self->GetParent->{'encoding'}, $self->GetText() );
    $self->SetSavePoint;
}

sub Replace {
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

sub insert_text {
    my ($self, $text, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->InsertText($pos, $text);
    $pos += length $text;
    $self->SetSelection( $pos, $pos );
}

sub move_text_up {
    my ($self) = @_;
    my ($old_start, $old_end) = $self->GetSelection;
    my $old_start_line = $self->LineFromPosition( $old_start );
    my $old_end_line = $self->LineFromPosition( $old_end );
    $self->BeginUndoAction();
    if ($old_start == $old_end) {
        return unless $old_start_line; # need space above
        my $col_pos = $old_start - $self->PositionFromLine( $old_start_line );
        $self->LineTranspose;
        $self->GotoPos ( $self->PositionFromLine( $old_start_line - 1 ) + $col_pos);
    } elsif ($old_start_line != $old_end_line) {
    }
    $self->EndUndoAction();
}

sub move_text_down {
    my ($self) = @_;
    my ($old_start, $old_end) = $self->GetSelection;
    my $old_start_line = $self->LineFromPosition( $old_start );
    my $old_end_line = $self->LineFromPosition( $old_end );
    $self->BeginUndoAction();
    if ($old_start == $old_end) {
        return unless $old_start_line < $self->GetLineCount; # need space above
        my $col_pos = $old_start - $self->PositionFromLine( $old_start_line );
        $self->GotoLine( $old_start_line + 1 );
        $self->LineTranspose;
        $self->GotoPos ( $self->PositionFromLine( $old_start_line + 1 ) + $col_pos);
    } elsif ($old_start_line != $old_end_line) {
    }
    $self->EndUndoAction();
}

sub move_text_left {
    my ($self) = @_;
    
    #$self->SetCurrentPos(1);
    $self->SetSelection(1, 5);
# say $self->GetSelectionStart();
# say $self->GetSelectionEnd();

}

sub move_text_right {
    my ($self) = @_;

}


sub goto_last_edit { $_[0]->GotoPos( $_[0]->{'change_pos'}+1 ) }

sub goto_prev_block {
    my ($self) = @_;
    my $line = $self->get_prev_block_start( $self->GetSelectionStart );
    $self->GotoLine( $line ) if defined $line;
}

sub goto_next_block {
    my ($self) = @_;
    my $line = $self->get_next_block_start( $self->GetSelectionEnd );
    $self->GotoLine( $line ) if defined $line;
}


sub get_prev_block_start {
    my ($self, $pos) = @_;
    my $line_nr = $self->LineFromPosition( $pos );
    return if $line_nr == 0;
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
    return if $line_nr == $last_line_nr;
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
    return if $line_nr == 0;
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
    return if $line_nr == $last_line_nr;
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
        return unless defined $line;
        $self->{'sel_head'} = $start = $self->PositionFromLine( $line );
    } else {
        my $line = $self->get_prev_block_end( $end );
        return unless defined $line;
        $self->{'sel_head'} = $end = $self->GetLineEndPosition( $line ); 
        if ($end < $start) {
            my $line = $self->get_prev_block_start( $end );
            return unless defined $line;
            $self->{'sel_head'} = $end = $self->PositionFromLine( $line );
            ($start, $end) = ($end, $start);
        }
    }
    $self->SetSelection( $start, $end );
}
sub select_next_block {
    my ($self) = @_;
    my ($start, $end) = $self->GetSelection;
    $self->{'sel_head'} = $end unless exists $self->{'sel_head'};
    if ($self->{'sel_head'} == $end) {
        my $line = $self->get_next_block_end( $end );
        return unless defined $line;
        $self->{'sel_head'} = $start = $self->GetLineEndPosition( $line );
    } else {
        my $line = $self->get_next_block_start( $start );
        return unless defined $line;
        $self->{'sel_head'} = $start = $self->PositionFromLine( $line ); 
        if ($end < $start) {
            my $line = $self->get_next_block_end( $start );
            return unless defined $line;
            $self->{'sel_head'} = $start = $self->GetLineEndPosition( $line );
            ($start, $end) = ($end, $start);
        }
    }
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
