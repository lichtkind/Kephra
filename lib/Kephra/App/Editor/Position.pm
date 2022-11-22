use v5.12;
use warnings;

package Kephra::App::Editor::Position;

package Kephra::App::Editor;


sub word_edges {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    ($self->WordStartPosition( $pos, 1 ), $self->WordEndPosition( $pos, 1 ) );
}

sub block_edges {
    my ($self, $sel_start, $sel_end) = @_;
    $sel_start = $self->GetCurrentPos unless defined $sel_start;
    $sel_end //= $sel_start;
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    my $line_nr = $self->LineFromPosition( $sel_start );
    return unless $self->GetLine( $line_nr ) =~ /\S/;
    $line_nr-- while $line_nr > 0 and $self->GetLine( $line_nr ) =~ /\S/;
    $line_nr++ unless $self->GetLine( $line_nr ) =~ /\S/;
    my $block_start = $self->PositionFromLine( $line_nr );
    my $last_line_nr = $self->GetLineCount - 1;
    $line_nr = $self->LineFromPosition( $sel_start );
    $line_nr++ while $line_nr < $last_line_nr and $self->GetLine( $line_nr ) =~ /\S/;
    $line_nr-- unless $self->GetLine( $line_nr ) =~ /\S/;
    my $block_end = $self->GetLineEndPosition( $line_nr );
    return if $block_end < $sel_end;
    return if $sel_start == $block_start and $sel_end == $block_end;
    ($block_start, $block_end);
}

sub style_edges {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    my ($style_start, $style_end) = ($pos, $pos);
    my $style = $self->GetStyleAt( $pos);
    $style_start-- while $style_start and $self->GetStyleAt( $style_start ) == $style;
    $style_start++ if $self->GetStyleAt( $style_start ) != $style;
    my $last_pos = $self->GetTextLength - 1;
    $style_end++ while $style_end < $last_pos and $self->GetStyleAt( $style_end ) == $style;
    # $style_end-- if $self->GetStyleAt( $style_end ) != $style;
    ($style_start, $style_end);
}

sub sub_edges {
    my ($self, $sel_start, $sel_end) = @_;
    $sel_start = $self->GetCurrentPos unless defined $sel_start;
    $sel_end //= $sel_start;
    ($sel_start, $sel_end) = ($sel_end, $sel_start) if $sel_start > $sel_end;
    my $start_line = $self->prev_sub( $sel_start + 5 );
    return if $start_line == -1;
    my $sub_start = $self->PositionFromLine( $self->LineFromPosition( $start_line ) );
    $self->GotoPos( $sub_start );
    $self->SearchAnchor;
    my $bpos = $self->SearchNext( 0, '{');
    return if $bpos == -1;
    my $sub_end = $self->BraceMatch( $bpos );
    return if $sub_end == -1 or $sub_end < $sel_end;
    return if $sub_start == $sel_start and  $sub_end == $sel_end;
    ($sub_start, $sub_end+1);
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

sub prev_sub {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos-1 );
    $self->SearchAnchor;
    $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

sub next_sub {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos+1 );
    $self->SearchAnchor;
    $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

sub prev_construct_line_nr {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos-1 );
    $self->SearchAnchor;
    $self->SearchPrev( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

sub next_construct_line_nr {
    my ($self, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->GotoPos( $pos+1 );
    $self->SearchAnchor;
    $self->SearchNext( &Wx::wxSTC_FIND_REGEXP, '^\s*sub ');
}

1;
