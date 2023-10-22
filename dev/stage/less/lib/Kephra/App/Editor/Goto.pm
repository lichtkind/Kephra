use v5.12;
use warnings;

package Kephra::App::Editor::Goto;
package Kephra::App::Editor;




sub caret_left {
    my ($self) = @_;
    $self->del_caret_pos_cache();
    $self->GotoPos( $self->GetCurrentPos - 1 );
}
sub caret_right {
    my ($self) = @_;
    $self->del_caret_pos_cache();
    $self->GotoPos( $self->GetCurrentPos + 1 );
}

sub caret_up {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $line_nr = $self->LineFromPosition( $pos );
    return $self->GotoPos( 0 ) unless $line_nr;
    my ($col) = ($self->get_caret_pos_cache('caret_col'));
    unless (defined $col){
        $col = $self->GetColumn( $pos );
        $self->set_caret_pos_cache('caret_col', $col);
    }
    my $next_pos = $self->PositionFromLine( $line_nr - 1 ) + $col;
    my $line_end = $self->GetLineEndPosition( $line_nr - 1 );
    $self->GotoPos( $line_end < $next_pos ? $line_end : $next_pos );
}
sub caret_down {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $line_nr = $self->LineFromPosition( $pos );
    return $self->GotoPos( $self->GetLastPosition ) if $self->GetLineCount -1 == $line_nr;
    my ($col) = ($self->get_caret_pos_cache('caret_col'));
    unless (defined $col){
        $col = $self->GetColumn( $pos );
        $self->set_caret_pos_cache('caret_col', $col);
    }
    my $next_pos = $self->PositionFromLine( $line_nr + 1 ) + $col;
    my $line_end = $self->GetLineEndPosition( $line_nr + 1 );
    $self->GotoPos( $line_end < $next_pos ? $line_end : $next_pos );
}

my $page_size = 45;
sub caret_page_up {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $line_nr = $self->LineFromPosition( $pos );
    return unless $line_nr;
    my ($col) = ($self->get_caret_pos_cache('caret_col'));
    unless (defined $col){
        $col = $self->GetColumn( $pos );
        $self->set_caret_pos_cache('caret_col', $col);
    }
    $line_nr -= $page_size;
    $line_nr = 0 if $line_nr < 0;
    my $next_pos = $self->PositionFromLine( $line_nr) + $col;
    my $line_end = $self->GetLineEndPosition( $line_nr);
    $self->GotoPos( $line_end < $next_pos ? $line_end : $next_pos );
}
sub caret_page_down {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $line_nr = $self->LineFromPosition( $pos );
    my $last_line = $self->GetLineCount - 1;
    return if $line_nr == $last_line;
    my ($col) = ($self->get_caret_pos_cache('caret_col'));
    unless (defined $col){
        $col = $self->GetColumn( $pos );
        $self->set_caret_pos_cache('caret_col', $col);
    }
    $line_nr += $page_size;
    $line_nr = $last_line if $line_nr > $last_line;
    my $next_pos = $self->PositionFromLine( $line_nr ) + $col;
    my $line_end = $self->GetLineEndPosition( $line_nr );
    $self->GotoPos( $line_end < $next_pos ? $line_end : $next_pos );
}

sub goto_last_edit {
    my ($self) = @_;
    return $self->GotoPos( $self->{'change_pos'} ) unless $self->GetCurrentPos == $self->{'change_pos'} or $self->{'change_pos'} == -1;
    $self->GotoPos( $self->{'change_prev'} ) unless $self->{'change_prev'} == -1;
}


sub init_marker {
    my $self = shift;
    $self->{'marker'} = {};
    for my $line (@_) {
        $self->{'marker'}{ $line }++;
        $self->MarkerAdd( $line, 1)
    }
}

sub marker_lines {
    my ($self) = @_;
    return sort keys %{$self->{'marker'}};
}


sub toggle_marker {
    my ($self) = @_;
    my $line = 	$self->GetCurrentLine ();
    $self->MarkerGet( $line ) ? delete $self->{'marker'}{$line} : $self->{'marker'}{$line}++;
    $self->MarkerGet( $line ) ? $self->MarkerDelete( $line, 1) : $self->MarkerAdd( $line, 1);
}

sub delete_all_marker { $_[0]->MarkerDeleteAll(1); $_[0]->{'marker'} = {}; }

sub goto_prev_marker {
    my ($self) = @_;
    my $line = 	$self->GetCurrentLine ();
    $line-- if $self->MarkerGet( $line );
    my $target = $self->MarkerPrevious ( $line, 2);
    $target = $self->MarkerPrevious ( $self->GetLineCount, 2 ) if $target == -1;
    $self->GotoLine( $target ) if $target > -1;
}

sub goto_next_marker {
    my ($self) = @_;
    my $line = 	$self->GetCurrentLine ();
    $line++ if $self->MarkerGet( $line );
    my $target = $self->MarkerNext( $line, 2);
    $target = $self->MarkerNext( 0, 2 ) if $target == -1;
    $self->GotoLine( $target ) if $target > -1;
}

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

sub goto_prev_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->prev_sub;
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }

}
sub goto_next_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->next_sub;
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }
}

1;

