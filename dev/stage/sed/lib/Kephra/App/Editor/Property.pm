use v5.12;
use warnings;

package Kephra::App::Editor::Property;

package Kephra::App::Editor;



sub set_tab_size {
    my ($self, $size) = @_;
    return unless defined $size;
    #$size *= 2 if $^O eq 'darwin';
    $self->SetTabWidth($size);
    $self->SetIndent($size);
    $self->SetHighlightGuide($size);
    my $menu = $self->GetParent->GetMenuBar;
    $menu->Check( 15200 + $size, 1 ) if ref $menu;

}

sub set_tab_usage {
    my ($self, $usage) = @_;
    $self->SetUseTabs($usage);
}

sub toggle_tab_usage {
    my ($self) = @_;
    $self->{'tab_usage'} = !$self->GetUseTabs();
    $self->set_tab_usage( $self->{'tab_usage'} );
    $self->GetParent->GetMenuBar->Check(15100, !$self->{'tab_usage'});
}

1;
