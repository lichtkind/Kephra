use v5.12;
use warnings;
use Wx;

package Kephra::App::SearchBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent ) = @_;
    #return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'text'} = Wx::TextCtrl->new( $self, -1, '', [-1, -1], [200, 25], &Wx::wxTE_PROCESS_ENTER);
    $self->{'btn'}{'first'} = Wx::Button->new( $self, -1, 'Find',  [-1, -1], [-1, -1] );
    $self->{'btn'}{'prev'}  = Wx::Button->new( $self, -1, '<',   [-1, -1], [-1, -1] );
    $self->{'btn'}{'next'}  = Wx::Button->new( $self, -1, '>',   [-1, -1], [-1, -1] );
    
    Wx::Event::EVT_KEY_DOWN( $self->{'text'}, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode;
        my $mod = $event->GetModifiers(); # say "$mod : ", chr($code);
         if   ($code == &Wx::WXK_UP)     {   }
         elsif($code == &Wx::WXK_DOWN)   {   }
         else { $event->Skip }
    });

    
    my $sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $sizer->AddSpacer( 40);
    $sizer->Add( $self->{'text'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'btn'}{'first'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->Add( $self->{'btn'}{'prev'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->Add( $self->{'btn'}{'next'}, 0, &Wx::wxGROW | &Wx::wxALL, 10);
    $sizer->Add( 0, 1, &Wx::wxEXPAND, 10);

    $self->SetSizer($sizer);

    $self;
}

1;
