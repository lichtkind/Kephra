#!/usr/bin/perl
use v5.12;
use warnings;

use strict;
keylog->new->MainLoop;

package keylog;
use parent qw(Wx::App);
use Wx;
use Wx::STC;

sub OnInit {
    my( $this ) = @_;
    my( $frame ) = Wx::Frame->new(undef, -1, "simpler keylogger", [-1,-1], [450, 700 ] );
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    $frame->Centre( );
    my $ed = Wx::StyledTextCtrl->new($frame, -1);
    $ed->AppendText("chr\tutf\tord\traw\tflags\n");
    Wx::Window::SetFocus($ed);

    Wx::Event::EVT_KEY_DOWN($ed , sub {
        my ($ed, $event) = @_;
        my $code = $event->GetUnicodeKey;
        $ed->AppendText( 
            chr($code). "\t$code\t" . 
            $event->GetKeyCode . "\t" . 
            $event->GetRawKeyCode . "\t" . 
            #$event->GetRawKeyFlags . 
            " \n"
        );
    });

    $this->SetTopWindow( $frame );
    $frame->Show( 1 );
    1;
}

