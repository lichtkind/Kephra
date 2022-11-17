use v5.12;
use warnings;

package Kephra::App::Editor::Select;

package Kephra::App::Editor;

sub expand_selecton {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
    my $start_line = $self->LineFromPosition( $start_pos );
    my $end_line = $self->LineFromPosition( $end_pos );
    my $line_start = $self->PositionFromLine( $start_line );
    my $line_end = $self->GetLineEndPosition( $start_line );
    my @selection;
    if ($start_line == $end_line) {
        if ($start_pos == $end_pos)      { @selection = $self->word_edges( $start_pos ) }
        elsif ($line_start != $start_pos 
           or  $line_end != $end_pos)    { @selection = $self->expression_edges($start_pos, $end_pos, $line_start, $line_end) }
        else                             { @selection = $self->construct_edges($start_pos, $end_pos) }
    } else                               { @selection = $self->construct_edges($start_pos, $end_pos) }
    # select all if no construct to be found
    @selection = (0, $self->GetTextLength - 1 ) if $selection[0] == $start_pos and $selection[1] == $end_pos;
    $self->SetSelection( @selection );
    push @{ $self->{'select_stack'} }, \@selection;
    
}

sub shrink_selecton {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
say "shrink $start_pos, $end_pos";
    return if $start_pos == $end_pos;
    return unless exists $self->{'select_stack'};
    my $pos = pop @{$self->{'select_stack'} };
    delete $self->{'select_stack'} unless @{$self->{'select_stack'} };
    $self->SetSelection( @$pos );
}

sub word_edges {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my $line = $self->LineFromPosition( $pos );
    my $cursor = $self->PositionFromLine( $line );
    my @word_pos = ();
    $self->SetCurrentPos( $cursor );
    $self->SearchAnchor;
    if ($cursor == $pos){
        $word_pos[1] = $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '\W' );
        return ($self->LineFromPosition( $word_pos[1] ) != $line) ? ($pos, $pos + 1) : ($pos, $word_pos[1]);
    }
    while ($cursor <= $pos-1){
        $word_pos[0] = $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '\w' );
        $self->SearchAnchor;
        $word_pos[1] = $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '\W' );
        $self->SearchAnchor;
        $cursor = $word_pos[1];
    }
    $word_pos[0] > $pos ? ($pos, $pos + 1) : @word_pos;
}

sub expression_edges {
    my ($self, $start, $end, $line_start, $line_end) = @_;
    my ($new_start, $new_rend);
    
    ($start, $end)
    
}

sub construct_edges {
    my ($self, $start, $end) = @_;
    # 
    ($start, $end)
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
#say "$_ : ", $self->GetSelectionNCaret($_) for 1..6;
#say '      '.$self->GetSelections();
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
# $self->SetSelectionNCaret
}
# &Wx::wxSTC_MULTIPASTE_EACH

1;
