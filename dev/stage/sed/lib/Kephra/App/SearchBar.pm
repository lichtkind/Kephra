use v5.12;
use warnings;
use Wx;

package Kephra::App::SearchBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'data'} = { wrap => 1};
    $self->{'lbl'} =  Wx::StaticText->new($self, -1, 'Find:' );
    $self->{'text'} = Wx::TextCtrl->new( $self, -1, '', [-1, -1], [200, 25], &Wx::wxTE_PROCESS_ENTER);
    $self->{'expand'} = Wx::Button->new( $self, -1, '=',     [-1, -1], [30, 20] );
    $self->{'first'} = Wx::Button->new( $self, -1, 'First',  [-1, -1], [50, -1] );
    $self->{'prev'}  = Wx::Button->new( $self, -1, '<',     [-1, -1], [30, -1] );
    $self->{'next'}  = Wx::Button->new( $self, -1, '>',     [-1, -1], [30, -1] );
    $self->{'case'}  = Wx::CheckBox->new( $self, -1, 'Case');
    $self->{'word'}  = Wx::CheckBox->new( $self, -1, 'Word');
    $self->{'start'} = Wx::CheckBox->new( $self, -1, 'Start');
    $self->{'regex'} = Wx::CheckBox->new( $self, -1, 'Rx');
    $self->{'wrap'}  = Wx::CheckBox->new( $self, -1, 'Wrap');
    $self->{'close'} = Wx::Button->new( $self, -1, 'X',     [-1, -1], [30, 20] );
    $self->{'text'}->SetToolTip('search term');
    $self->{'first'}->SetToolTip('go to first match of search term');
    $self->{'prev'}->SetToolTip('go to previous match of search term');
    $self->{'next'}->SetToolTip('go to next match of search term');
    $self->{'case'}->SetToolTip('apply case sensitive search if checked');
    $self->{'word'}->SetToolTip('view search term as surrounded by none word characters');
    $self->{'start'}->SetToolTip('search term has to be beginning of a word');
    $self->{'regex'}->SetToolTip('view search term as regular expression');
    $self->{'wrap'}->SetToolTip('after last match go to first again and vice versa');
    $self->{'expand'}->SetToolTip('toggle replace bar visibility');
    $self->{'close'}->SetToolTip('close search bar');
    $self->{'wrap'}->SetValue( $self->{'data'}{'wrap'} );

    Wx::Event::EVT_BUTTON( $self, $self->{'first'},  sub { $self->find_first });
    Wx::Event::EVT_BUTTON( $self, $self->{'prev'},   sub { $self->find_prev  });
    Wx::Event::EVT_BUTTON( $self, $self->{'next'},   sub { $self->find_next  });
    Wx::Event::EVT_BUTTON( $self, $self->{'expand'}, sub { $self->replace_bar->show( not $self->replace_bar->IsShown() ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->close      });

    Wx::Event::EVT_TEXT( $self, $self->{'text'}, sub { $self->find_first( ); $_[1]->Skip; });
    
    Wx::Event::EVT_CHECKBOX( $self, $self->{'case'},  sub { $self->update_flags } );
    Wx::Event::EVT_CHECKBOX( $self, $self->{'word'},  sub { $self->update_flags } );
    Wx::Event::EVT_CHECKBOX( $self, $self->{'start'}, sub { $self->update_flags } );
    Wx::Event::EVT_CHECKBOX( $self, $self->{'regex'}, sub { $self->update_flags } );
    
    Wx::Event::EVT_KEY_DOWN( $self->{'text'}, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode; # my $mod = $event->GetModifiers();
        if   (                         $code == &Wx::WXK_UP )     { $self->find_prev  }
        elsif(                         $code == &Wx::WXK_DOWN )   { $self->find_next  }
        elsif( $event->ShiftDown   and $code == &Wx::WXK_RETURN)  { $self->find_prev  }
        elsif(                         $code == &Wx::WXK_RETURN ) { $self->find_next  }
        elsif(                         $code == &Wx::WXK_ESCAPE)  { $self->close  }
        elsif( $event->ControlDown and $code == ord('R'))         { $self->replace_bar->enter  }
        elsif( $event->ControlDown and $event->ShiftDown and $code == ord('F'))     { $self->replace_bar->enter  }
        elsif( $event->ControlDown and $code == ord('F'))         { $self->editor->SetFocus  }
        else { $event->Skip }
    });
    
    my $attr = &Wx::wxGROW | &Wx::wxTOP|&Wx::wxDOWN;
    my $sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'lbl'},  0, $attr|&Wx::wxALIGN_CENTER_VERTICAL, 20);
    $sizer->AddSpacer( 36);
    $sizer->Add( $self->{'text'},  0, $attr, 10);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'first'}, 0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'prev'},  0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'next'},  0, $attr, 10);
    $sizer->Add( 0, 1, &Wx::wxEXPAND, 0);
    #$sizer->AddSpacer( 140);
    $sizer->Add( $self->{'case'},  0, $attr, 10);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'word'},  0, $attr, 10);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'start'},  0, $attr, 10);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'regex'},  0, $attr, 10);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'wrap'},  0, $attr, 10);
    $sizer->Add( 0, 1, &Wx::wxEXPAND, 0);
    $sizer->Add( $self->{'expand'},  0, $attr, 15);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'close'}, 0, $attr, 15);
    $sizer->AddSpacer( 10);
    $self->SetSizer($sizer);

    $self->update_flags;
    $self;
}

sub editor      { $_[0]->GetParent->{'ed'} }
sub replace_bar { $_[0]->GetParent->{'rb'} }

sub show {
    my ($self, $visible) = @_;
    $self->Show( $visible );
    $self->GetParent->Layout;
}

sub enter {
    my ($self) = @_;
    $self->show(1);
    $self->{'text'}->SetFocus();
}

sub close {
    my ($self) = @_;
    $self->show(0);
    $self->GetParent->{'rb'}->show(0);
    $self->GetParent->{'ed'}->SetFocus;
}

sub find_first {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    $ed->SetSelection( 0, 0 );
    $ed->SearchAnchor;
    my $pos = $ed->SearchNext( $self->{'flags'}, $self->{'text'}->GetValue );
    $ed->SetSelection( $start, $start ) if $pos == -1;
    $ed->EnsureCaretVisible;
    $pos > -1;
}

sub find_prev {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    my $wrap = $self->{'wrap'}->GetValue;
    $ed->SetSelection( $start, $start );
    $ed->SearchAnchor;
    my $pos = $ed->SearchPrev( $self->{'flags'},  $self->{'text'}->GetValue );
    if ($pos == -1){
        $ed->SetSelection( $ed->GetLength , $ed->GetLength );
        $ed->SearchAnchor();
        $pos = $ed->SearchPrev( $self->{'flags'},  $self->{'text'}->GetValue ) if $wrap;
        $ed->SetSelection( $start, $end ) if $pos == -1;
    }
    $ed->EnsureCaretVisible;
    $pos > -1;
}

sub find_next {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    my $wrap = $self->{'wrap'}->GetValue;
    $ed->SetSelection( $end, $end );
    $ed->SearchAnchor;
    my $pos = $ed->SearchNext( $self->{'flags'},  $self->{'text'}->GetValue );
    if ($pos == -1){
        $ed->SetSelection( 0, 0 );
        $ed->SearchAnchor;
        $pos = $ed->SearchNext( $self->{'flags'},  $self->{'text'}->GetValue ) if $wrap;
        $ed->SetSelection( $start, $end ) if $pos == -1;
    }
    $ed->EnsureCaretVisible;
    $pos > -1;
}


sub line_nr_around {
    my ($self) = @_;
    my $line_nr = $self->GetCurrentLine
}

sub update_flags {
    my ($self) = @_;
    $self->{'flags'} = (&Wx::wxSTC_FIND_MATCHCASE * $self->{'case'}->GetValue )
                     | (&Wx::wxSTC_FIND_WHOLEWORD * $self->{'word'}->GetValue )
                     | (&Wx::wxSTC_FIND_WORDSTART * $self->{'start'}->GetValue)
                     | (&Wx::wxSTC_FIND_REGEXP    * $self->{'regex'}->GetValue);
}



1;