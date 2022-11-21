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
        my @word_edge = $self->word_edges( $start_pos );
        if  ( $start_pos >= $word_edge[0] and $end_pos <= $word_edge[1]  and
             ($start_pos != $word_edge[0] or  $end_pos != $word_edge[1])     )
            { @selection = @word_edge }                                 # select word if got less
        elsif ($start_pos == $line_start and $end_pos == $line_end) { } # skip if already got full line
        else {
            @selection = ($line_start, $line_end);
# select ' '
# select " "
# select ( )
# select [ ]
# select [ ]
# select { }
# select / /




        }
    } 
    unless (@selection) { # select construct: sub for if
        my $block_start = $self->PositionFromLine( $self->get_prev_block_start( $end_pos ) );
        my $block_end = $self->GetLineEndPosition( $self->get_next_block_end( $start_pos ) );
say "start  $start_pos - $end_pos  block $block_start  $block_end";
        
        if (   $block_start <= $start_pos and $block_end >= $end_pos 
         ){
            @selection = ($block_start, $block_end);
        }
        # @selection = $self->construct_edges($start_pos, $end_pos) 
    }
    @selection = (0, $self->GetTextLength - 1 ) unless @selection; # select all
    $self->SetSelection( @selection );
# select block
# select if () {} 
# select unless () {} 
# select while () {} 
# select until () {} 
# select for () {} 
# select foreach () {} 
# select sub () {} 
    
}

sub shrink_selecton {
    my ($self) = @_;
    my ($start_pos, $end_pos) = $self->GetSelection;
# say "shrink $start_pos, $end_pos ", $self->{'select_stack'};
    return if $start_pos == $end_pos;
    my @selection;
    $self->SetSelection( $start_pos, $end_pos );
}


sub expression_edges {
    my ($self, $start, $end, $line_start, $line_end, $line) = @_;
    my ($new_start, $new_rend);
    say $self->	GetLineState( $line );
    ($start, $end)
    
}

sub construct_edges {
    my ($self, $start, $end) = @_;
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
