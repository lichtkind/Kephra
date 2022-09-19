use v5.12;
use warnings;
use Wx;

package Kephra::App::SearchBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'text'} = Wx::TextCtrl->new( $self, -1, '', [-1, -1], [200, 25], &Wx::wxTE_PROCESS_ENTER);
    $self->{'close'} = Wx::Button->new( $self, -1, 'X',     [-1, -1], [30, 20] );
    $self->{'first'} = Wx::Button->new( $self, -1, 'Find',  [-1, -1], [-1, -1] );
    $self->{'prev'}  = Wx::Button->new( $self, -1, '<',     [-1, -1], [-1, -1] );
    $self->{'next'}  = Wx::Button->new( $self, -1, '>',     [-1, -1], [-1, -1] );
    $self->{'close'}->SetToolTip('close search bar');

    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->close     });
    Wx::Event::EVT_BUTTON( $self, $self->{'first'},  sub { $self->find      });
    Wx::Event::EVT_BUTTON( $self, $self->{'prev'},   sub { $self->find_prev });
    Wx::Event::EVT_BUTTON( $self, $self->{'next'},   sub { $self->find_next });

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'text'}, sub { $self->find  });
    
    Wx::Event::EVT_KEY_DOWN( $self->{'text'}, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode;
        my $mod = $event->GetModifiers();
        if   ( $code == &Wx::WXK_UP )     { $self->find_prev  }
        elsif( $code == &Wx::WXK_DOWN )   { $self->find_next  }
        elsif( $event->ControlDown and $code == ord('Q')) { $self->close  }
        elsif( $event->ControlDown and $code == ord('F')) { $parent->{'ed'}->SetFocus  }
        else { $event->Skip }
    });
    
    my $sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $sizer->AddSpacer( 5);
    $sizer->Add( $self->{'close'}, 0, &Wx::wxGROW | &Wx::wxTOP|&Wx::wxDOWN, 15);
    $sizer->Add( $self->{'text'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'first'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->Add( $self->{'prev'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->Add( $self->{'next'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->Add( 0, 1, &Wx::wxEXPAND, 10);
    $self->SetSizer($sizer);
    $self;
}


sub enter {
    my ($self) = @_;
    $self->Show(1);
    $self->GetParent->Layout();
    $self->{'text'}->SetFocus();
}

sub find {
    my ($self) = @_;
    my $ed = $self->GetParent->{'ed'};
    my $old_start = $ed->GetSelectionStart();
    my $old_end = $ed->GetSelectionEnd();
    $ed->SetSelection( 0, 0 );
    $ed->SearchAnchor();
    my $pos = $ed->SearchNext( 0,  $self->{'text'}->GetValue );
    $ed->SetSelection( $old_start, $old_end ) if $pos == -1;
    $ed->EnsureCaretVisible ();
}

sub find_prev {
    my ($self) = @_;
    my $ed = $self->GetParent->{'ed'};
    my $old_start = $ed->GetSelectionStart();
    my $old_end = $ed->GetSelectionEnd();
    $ed->SetSelection( $old_start, $old_start );
    $ed->SearchAnchor();
    my $pos = $ed->SearchPrev( 0,  $self->{'text'}->GetValue );
    if ($pos == -1){
        $ed->SetSelection( $ed->GetLength , $ed->GetLength  );
        $ed->SearchAnchor();
        my $pos = $ed->SearchPrev( 0,  $self->{'text'}->GetValue );
        $ed->SetSelection( $old_start, $old_end ) if $pos == -1;
    }
    $ed->EnsureCaretVisible ();
}

sub find_next {
    my ($self) = @_;
    my $ed = $self->GetParent->{'ed'};
    my $old_start = $ed->GetSelectionStart();
    my $old_end = $ed->GetSelectionEnd();
    $ed->SetSelection( $old_end, $old_end );
    $ed->SearchAnchor();
    my $pos = $ed->SearchNext( 0,  $self->{'text'}->GetValue );
    if ($pos == -1){
        $ed->SetSelection( 0, 0 );
        $ed->SearchAnchor();
        my $pos = $ed->SearchNext( 0,  $self->{'text'}->GetValue );
        $ed->SetSelection( $old_start, $old_end ) if $pos == -1;
    }
    $ed->EnsureCaretVisible ();
}

sub close {
    my ($self) = @_;
    $self->Hide();
    $self->GetParent->Layout();
    $self->GetParent->{'ed'}->SetFocus;
}


1;
