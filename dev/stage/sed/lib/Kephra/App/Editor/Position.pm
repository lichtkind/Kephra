use v5.12;
use warnings;

package Kephra::App::Editor::Position;

package Kephra::App::Editor;


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

1;
