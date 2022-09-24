use v5.12;
use warnings;

package Kephra::App::Editor::MoveText;

sub move_line {
    my ($ed, $from, $to) = @_;
    return unless defined $to and $from < $ed->GetLineCount and $to < $ed->GetLineCount;
    $from = $ed->GetLineCount + $from if $from < 0;
    $to =   $ed->GetLineCount + $to   if $to < 0;
    return if $from == $to;
    my $last_line_nr = $ed->GetLineCount - 1;
    if ($from  == $last_line_nr) {
        $ed->GotoLine( $from );
        $ed->LineTranspose;
        $from--;
    }
    $ed->SetSelection( $ed->PositionFromLine( $from ),
                         $ed->PositionFromLine( $from + 1 ) );
    my $line = $ed->GetSelectedText( );
    $ed->ReplaceSelection( '' );
    if ($to == $last_line_nr) {
        $ed->InsertText( $ed->PositionFromLine($to - 1), $line );
        $ed->GotoLine( $to );
        $ed->LineTranspose;
    } else { $ed->InsertText( $ed->PositionFromLine($to), $line ) }
}

sub move_block {
    my ($ed, $begin, $size, $newbegin) = @_;
    return unless defined $newbegin and $begin < $ed->GetLineCount
                                    and $size    < $ed->GetLineCount and $size > 0 
                                    and $newbegin  < $ed->GetLineCount and $begin != $newbegin;
    $begin    = $ed->GetLineCount + $begin    if $begin < 0;
    $newbegin = $ed->GetLineCount + $newbegin if $newbegin < 0;
    
    $ed->GotoPos( $ed->GetTextLength );
    $ed->NewLine ();
    $ed->SetSelection( $ed->PositionFromLine( $begin ),
                         $ed->PositionFromLine( $begin + $size ) );
    my $text = $ed->GetSelectedText( );
    $ed->ReplaceSelection( '' );
    $ed->InsertText( $ed->PositionFromLine( $newbegin ), $text );
    $ed->SetSelection( $ed->GetLineEndPosition( $ed->GetLineCount - 2 ),
                       $ed->PositionFromLine( $ed->GetLineCount - 1)    );
    $ed->ReplaceSelection( '' );
}

sub up {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    return unless $start_line; # need space above
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $ed->PositionFromLine( $start_line );
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $ed->LineTranspose;
        $ed->GotoPos ( $ed->PositionFromLine( $start_line - 1 ) + $start_col);
    } elsif ($start_line != $end_line) {
        my $end_col =  $end_pos - $ed->PositionFromLine( $end_line );
        move_line( $ed, $start_line - 1, $end_line);
        $ed->SetSelection( $ed->PositionFromLine( $start_line - 1 ) + $start_col,
                             $ed->PositionFromLine( $end_line - 1 ) + $end_col );
    } else {}
    $ed->EndUndoAction();
}

sub down {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $ed->PositionFromLine( $start_line );
    my $end_col = $end_pos - $ed->PositionFromLine( $end_line );
    $ed->BeginUndoAction();
    if ( $end_line + 1 == $ed->GetLineCount ) {
        $ed->GotoLine( $start_line );
        $ed->NewLine;
    } elsif ($start_pos == $end_pos) {
        $ed->GotoLine( $start_line + 1 );
        $ed->LineTranspose;
        $ed->GotoPos ( $ed->PositionFromLine( $start_line + 1 ) + $start_col);
    } elsif ($start_line != $end_line) {
        move_line( $ed, $end_line + 1, $start_line);
    } else { return }
    $ed->SetSelection( $ed->PositionFromLine( $start_line + 1 ) + $start_col,
                         $ed->PositionFromLine( $end_line + 1 ) + $end_col );
    $ed->EndUndoAction();
}

sub page_up {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    return unless $start_line; # need space above
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $ed->PositionFromLine( $start_line );
    my $target_line = $start_line - 50;
    $target_line = 0 if $target_line < 0;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        move_line( $ed, $start_line, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );

    } elsif ($start_line != $end_line) {
        my $end_col =  $end_pos - $ed->PositionFromLine( $end_line );
        move_block( $ed,  $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line - $start_line + $end_line ) + $end_col );
    } else {}
    $ed->EndUndoAction();
    $ed->ScrollToLine( $target_line - $start_line + $end_line + 5 );
    $ed->ScrollToLine( $target_line - 5 );
}

sub page_down {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $ed->PositionFromLine( $start_line );
    my $target_line = $start_line + 50;
    my $last_possible_line = $ed->GetLineCount - 1 - $end_line + $start_line;
    $target_line = $last_possible_line if $target_line > $last_possible_line;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        move_line( $ed, $start_line, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );
    } elsif ($start_line != $end_line) {
        my $end_col =  $end_pos - $ed->PositionFromLine( $end_line );
        move_block( $ed,  $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line - $start_line + $end_line ) + $end_col );
    } else {  }
    $ed->EndUndoAction();
    $ed->ScrollToLine( $target_line - $start_line + $end_line + 5 );
    $ed->ScrollToLine( $target_line - 5 );
}

sub start {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $ed->PositionFromLine( $start_line );
    my $end_col = $end_pos - $ed->PositionFromLine( $end_line );
    return unless $start_line; # need space above    GetFirstVisibleLine
    my $target_line = 0;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        move_line( $ed, $start_line, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );
    } elsif ($start_line != $end_line) {
        my $end_col =  $end_pos - $ed->PositionFromLine( $end_line );
        move_block( $ed,  $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line - $start_line + $end_line ) + $end_col );
    } else {}
    $ed->EndUndoAction();
    $ed->ScrollToLine( 0 );
}

sub end {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $start_pos - $ed->PositionFromLine( $start_line );
    my $end_col = $end_pos - $ed->PositionFromLine( $end_line );
    my $last_line = $ed->GetLineCount - 1;
    my $target_line = $last_line - $end_line + $start_line;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        move_line( $ed, $start_line, $last_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );
    } elsif ($start_line != $end_line) {
        move_block( $ed,  $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line - $start_line + $end_line ) + $end_col );
    } else { }
    $ed->EndUndoAction();
    $ed->ScrollToLine( $last_line );
}

sub line_left {
    my ($ed, $line_nr) = @_;
    return unless defined $line_nr;
    $ed->SetSelection( $ed->PositionFromLine( $line_nr ),
                         $ed->PositionFromLine( $line_nr ) + 1  );
    my $s = $ed->GetSelectedText;
    $s = $ed->{tab_space} if $s eq "\t";
    if (substr( $s, 0, 1 ) eq ' '){ chop $s }
    else                          { return 0 }
    $ed->ReplaceSelection( $s );
    return 1;
}

sub line_right {
    my ($ed, $line_nr) = @_;
    return unless defined $line_nr;
    $ed->SetSelection( $ed->PositionFromLine( $line_nr ),
                         $ed->GetLineEndPosition( $line_nr )  );
    my $line = $ed->GetSelectedText( );
    $line =~ s/\t/$ed->{tab_space}/g if $line =~ /\t/;
    $ed->ReplaceSelection( ' '.$line );
}

sub left {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $start_pos-- if line_left( $ed, $start_line );
        $ed->GotoPos ( $start_pos );
    } elsif ($start_line != $end_line) {
        my $end_col = $end_pos - $ed->PositionFromLine( $end_line );
        $start_pos-- if line_left( $ed, $start_line );
        $end_col-- if line_left( $ed, $end_line );
        line_left( $ed, $_ ) for $start_line + 1 .. $end_line - 1;
        $ed->SetSelection( $start_pos, $ed->PositionFromLine( $end_line ) + $end_col );
    } else {}
    $ed->EndUndoAction();
}

sub right {
    my ($ed) = @_;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        line_right( $ed, $start_line );
        $ed->GotoPos ( $start_pos + 1);
    } elsif ($start_line != $end_line) {
        line_right( $ed, $_ ) for $start_line .. $end_line;
        $ed->SetSelection( $start_pos + 1, $end_pos + 1 + $end_line -  $start_line);
    }  else {}
    $ed->EndUndoAction();
}

1;