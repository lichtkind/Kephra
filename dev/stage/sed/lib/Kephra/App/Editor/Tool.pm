use v5.12;
use warnings;

package Kephra::App::Editor::Tool;

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

    toggle_comment_line( $self, $_ ) for $self->LineFromPosition( $old_start ) ..
                                         $self->LineFromPosition( $old_end );
    $self->GotoPos( $old_end );
    $self->EndUndoAction();
}

sub toggle_block_comment {
    my ($self) = @_;
    my ($old_start, $old_end) = $self->GetSelection;
    $self->BeginUndoAction();

    toggle_block_comment_line( $self, $_ ) for $self->LineFromPosition( $old_start ) ..
                                               $self->LineFromPosition( $old_end );
    $self->GotoPos( $old_end );
    $self->EndUndoAction();
}


1;
