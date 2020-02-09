#!/usr/bin/perl
use v5.12;
use warnings;

use strict;
proto->new->MainLoop;

package proto;
use parent qw(Wx::App);
use Wx;
use Wx::STC;

sub OnInit {
    my( $app ) = @_;
    my( $frame ) = Wx::Frame->new(undef, -1, "Prototype Starting point Zero ", [-1,-1], [450, 350 ] );
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    my $ed = Wx::StyledTextCtrl->new($frame, -1);
    Wx::Window::SetFocus($ed);

    $frame->Centre( );
    $frame->Show( 1 );
    $app->SetTopWindow( $frame );
  1;
}

