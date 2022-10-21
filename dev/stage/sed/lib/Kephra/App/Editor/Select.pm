use v5.12;
use warnings;

package Kephra::App::Editor::Select;

package Kephra::App::Editor;

sub expand_selecton {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
# say " $start_pos - $end_pos ", $self->GetCurrentPos;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );

    if ($start_line == $end_line) {
        if ($start_pos == $end_pos){ $self->select_word( $start_pos )
            

        } else {
            $self->SetSelection( $self->PositionFromLine( $start_line ), 
                                 $self->GetLineEndPosition( $start_line ) );
        }
    } else {
        $self->SetSelection( 0, $self->GetTextLength - 1 );
    }
    
}

sub shrink_selecton {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    return if $start_pos == $end_pos;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );
    
}

sub select_word {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->SetCurrentPos( $pos );
    $self->SearchAnchor;
say "pos $pos ";
    my $word_start = $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '\w' );
say 'W'  if $word_start == $pos;
    $word_start = $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '\s' );
say 's' if $word_start == $pos;
            #~ $word_end = $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '\w' );
#~ # say " $start_pos > $word_end $word_start";
            #~ $self->SetSelection( $word_start, $word_end );
}

sub select_line {
    my ($self, $line) = @_;
    $line = $self->GetCurrentLine unless defined $line;
    $self->SetSelection( $self->PositionFromLine( $line ), 
                         $self->PositionFromLine( $line+1 ) );
    # $self->SetSelection( $self->PositionFromLine( $line ), $self->GetLineEndPosition( $line ) );
    # $self->GetLineIndentPosition
}

sub select_block {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $block_start = $self->PositionFromLine( $self->get_prev_block_start( $pos + 1 ) );
    my $block_end = $self->GetLineEndPosition( $self->get_next_block_end( $pos - 1 ) );
    $self->SetSelection( $block_start, $block_end );
}

sub select_all {
    my ($self) = @_;
    $self->SetSelection( 0, $self->GetTextLength - 1 );
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

#say $self->GetRect;
# ->SelectionIsRectangle
# ->HomeRectExtend ()
# ->VCHomeRectExtend 
# ->SetInsertionPoint
# ->GetMultipleSelection
# ->GetRectangularSelectionAnchor()
# ->GetRectangularSelectionCaret()
# 

sub select_rect_up {
    my ($self) = @_;
    $self->LineUpRectExtend;
#say "$_ : ", $self->GetSelectionNCaret($_) for 1..5;
}


sub select_rect_down {
    my ($self) = @_;
    $self->LineDownRectExtend;
}


sub select_rect_left {
    my ($self) = @_;
    $self->CharLeftRectExtend;
}


sub select_rect_right {
    my ($self) = @_;
    $self->CharRightRectExtend;
}


1;
