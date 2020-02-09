#!/usr/bin/perl
use v5.12;
use warnings;

use strict;
proto->new->MainLoop;

package proto;
use parent qw(Wx::App);
use Wx;
use Wx::STC;
my ($ed1, $ed2, $splitter);

sub OnInit {
    my( $app ) = @_;
    my( $frame ) = Wx::Frame->new(undef, -1, "KephraCP splitter demo prototype ", [-1,-1], [650, 650 ] );
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    $splitter = Wx::SplitterWindow->new($frame);
    $ed1 = Wx::StyledTextCtrl->new($splitter, -1);
    $ed2 = Wx::StyledTextCtrl->new($splitter, -1);
    $splitter->SplitVertically( $ed1, $ed2, .5 );
    output("Ctrl+H:Horizontal, Ctrl+V:Vertical, Ctrl+U:Unsplit,\n Ctrl+Tab, Strg+Q:Quit");
    Wx::Window::SetFocus($ed1);

    Wx::Event::EVT_SPLITTER_SASH_POS_CHANGING($splitter, $splitter,sub { output("pos changing " . $_[1]->GetSashPosition) });
    Wx::Event::EVT_SPLITTER_SASH_POS_CHANGED( $splitter, $splitter,sub { output("pos changed " . $_[1]->GetSashPosition) });
    Wx::Event::EVT_SPLITTER_UNSPLIT(          $splitter, $splitter,sub { output("unsplit") }); 
    Wx::Event::EVT_SPLITTER_DCLICK(           $splitter, $splitter,sub { output("dclick: ".$_[1]->GetX.':'.$_[1]->GetY) });
    Wx::Event::EVT_KEY_DOWN       ($ed1, \&special_keys);
    Wx::Event::EVT_KEY_DOWN       ($ed2, \&special_keys);

    $app->SetTopWindow( $frame );
    $frame->Centre( );
    $frame->Show( 1 );
  1;
}

sub special_keys {
        my ($ed, $event) = @_;
        my $code = $event->GetUnicodeKey;
        if($code == &Wx::WXK_TAB and $event->ControlDown) { #
            if ($ed eq $splitter->GetWindow1())            { Wx::Window::SetFocus($splitter->GetWindow2())}
            else                                           { Wx::Window::SetFocus($splitter->GetWindow1())}
        } elsif($code == ord('H') and $event->ControlDown) { $splitter->Unsplit();$splitter->SplitHorizontally( $ed1, $ed2 )
        } elsif($code == ord('U') and $event->ControlDown) { $splitter->Unsplit();# $splitter->Initialize( $ed1 )
        } elsif($code == ord('Q') and $event->ControlDown) { $splitter->GetParent->Close()
        } elsif($code == ord('V') and $event->ControlDown) { $splitter->Unsplit();$splitter->SplitVertically( $ed1, $ed2 )
        } else                              { $event->Skip }
}

sub output { $ed1->SetText($_[0]); $ed2->SetText($_[0]); }
