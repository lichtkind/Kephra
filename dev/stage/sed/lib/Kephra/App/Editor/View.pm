use v5.12;
use warnings;

package Kephra::App::Editor::View;

package Kephra::App::Editor;


sub toggle_view_whitespace {
    my ($self) = @_;
    my $visible = not $self->GetViewWhiteSpace();
    $self->SetViewWhiteSpace( $visible );
    $self->GetParent->GetMenuBar->Check(16110, $visible);
}

sub toggle_view_eol {
    my ($self) = @_;
    my $visible = not $self->GetViewEOL();
    $self->SetViewEOL( $visible );
    $self->GetParent->GetMenuBar->Check(16120, $visible);
}

sub toggle_view_inden_guide {
    my ($self) = @_;
    my $visible = not $self->GetIndentationGuides();
    $self->SetIndentationGuides( $visible );
    $self->GetParent->GetMenuBar->Check(16130, $visible);
}

sub toggle_view_right_margin {
    my ($self) = @_;
    my $visible = not $self->GetEdgeMode;
    $self->SetEdgeMode( $visible ? &Wx::wxSTC_EDGE_LINE : 0 );
    $self->GetParent->GetMenuBar->Check(16140, $visible ? 1 : 0);
}

sub toggle_view_line_nr_margin {
    my ($self) = @_;
    my $visible = not $self->GetMarginWidth(1);
    $self->SetMarginWidth(1, ($visible ? 47 : 0) );
    $self->GetParent->GetMenuBar->Check(16210, $visible ? 1 : 0);
}

sub toggle_view_marker_margin {
    my ($self) = @_;
    my $visible = not $self->GetMarginWidth(2);
    $self->SetMarginWidth(2, ($visible ? 22 : 0) );
    $self->GetParent->GetMenuBar->Check(16220, $visible ? 1 : 0);
}

1;
