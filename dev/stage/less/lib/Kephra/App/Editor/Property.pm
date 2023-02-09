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
    $self->{'tab_size'} = $size;
    $self->{'tab_space'} = ' ' x $self->{'tab_size'};
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

sub set_EOL_lf   {
    my ($self) = @_;
    $self->SetEOLMode( &Wx::wxSTC_EOL_LF );
    $self->ConvertEOLs( &Wx::wxSTC_EOL_LF );
    $self->GetParent->GetMenuBar->Check(15410, 1);
}

sub set_EOL_cr   {
    my ($self) = @_;
    $self->SetEOLMode( &Wx::wxSTC_EOL_CR );
    $self->ConvertEOLs( &Wx::wxSTC_EOL_CR );
    $self->GetParent->GetMenuBar->Check(15420, 1);
}

sub set_EOL_crlf {
    my ($self) = @_;
    $self->SetEOLMode( &Wx::wxSTC_EOL_CRLF );
    $self->ConvertEOLs( &Wx::wxSTC_EOL_CRLF );
    $self->GetParent->GetMenuBar->Check(15430, 1);
}


1;
